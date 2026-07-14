# DwarfStar (ds4) on occ-laptop

Plan for running [antirez/ds4](https://github.com/antirez/ds4) — a DeepSeek V4 Flash/PRO native inference engine — on the Framework Strix Halo laptop.

## Hardware Profile

| Component | Detail |
|-----------|--------|
| Machine | Framework Laptop, AMD Strix Halo |
| CPU | AMD Ryzen AI 9 HX 370 (24 cores) |
| GPU | AMD Radeon 890M — gfx1150, 16 CUs, 2900 MHz |
| RAM | 94 GiB unified (LPDDR5X) |
| OS | NixOS unstable, kernel 7.0.14 |
| ROCm | 7.2.3 (hipcc, rocminfo, amdgpu driver) |
| Disk | 63 GB free on `/` (ZFS, 1.8T total) |

**ds4 backend match:** `strix-halo` (ROCm, gfx1151). This is the exact hardware ds4 targets.

## Model Choice

The **q2-imatrix** quant is the only viable option for 94 GiB RAM:

| Quant | Disk size | RAM needed | Fits? |
|-------|-----------|------------|-------|
| q2-imatrix | ~81 GB | 96/128 GB target | Yes (tight) |
| q2-q4-imatrix | ~98 GB | 128 GB target | No |
| q4-imatrix | ~153 GB | 256 GB target | No |
| PRO q2 | ~430 GB | 512 GB target | No |

File: `DeepSeek-V4-Flash-IQ2XXS-w2Q2K-AProjQ8-SExpQ8-OutQ8-chat-v2-imatrix.gguf`
Source: `https://huggingface.co/antirez/deepseek-v4-gguf`

## BIOS Changes (required, counter-intuitive)

### UMA Frame Buffer Size → minimum

**Set UMA Frame Buffer Size to the smallest available value: 512 MB or 2 GB.**

This is the opposite of what you'd expect, but it's confirmed by ds4 testing
(issue [#459](https://github.com/antirez/ds4/issues/459)) and AMD's own guidance:

| BIOS UMA | Max usable context | Result |
|----------|-------------------|--------|
| 2 GB | ctx=100,000 | PASS |
| 8 GB | — | FAIL |
| 16 GB | ctx=65,536 | FAIL |
| 32 GB | — | FAIL |
| 64 GB | — | FAIL |
| 96 GB | — | FAIL |

**Why:** The BIOS UMA reservation is a **static carveout** from the CPU
fine-grained memory pool. ROCm uses that pool for large tensor allocations.
The GTT aperture (kernel parameter) is what actually makes system RAM
available to the GPU for compute — the BIOS setting only wastes memory that
ROCm could otherwise use. AMD's official guidance for Strix Halo is to keep
the BIOS UMA reservation as small as possible.

### Where to find it

Enter BIOS (F2 at boot on Framework). Look under:
- **AMD CBS** → **NBIO Common Options** → **UMA Frame Buffer Size**
- Or **Advanced** → **AMD PBS** / **NBIO**

If only "Auto" and discrete sizes are offered, pick the smallest non-Auto
value (typically 512 MB or 2 GB).

### IOMMU

Disable IOMMU or set it to pass-through. The two approaches:

| Parameter | Effect |
|-----------|--------|
| `amd_iommu=off` | Disables IOMMU entirely (STRIXHALO.md recommendation) |
| `iommu=pt` | Pass-through mode — IOMMU on with minimal overhead (toolboxes community recommendation) |

Either should work. `iommu=pt` is preferred if your BIOS/board supports it
cleanly; fall back to `amd_iommu=off` if you see stability issues.

Some BIOSes also expose **IOMMU** as a toggle. If present, set it to
**Disabled** or **Auto**.

## Blockers

### 1. Disk Space (CRITICAL)

63 GB free. Model is 81 GB. Does not fit.

**Resolution options:**
- Download to external storage: set `DS4_GGUF_DIR` to point at an external NVMe/USB drive
- Free ~20 GB from the ZFS pool
- Use a dedicated SSD for model storage

### 2. GPU-Visible Memory Aperture (fixable)

`rocminfo` currently shows only ~47 GB GPU-visible memory (Pool 1: 49,325,292 KB).
The model weights alone are ~81 GiB; runtime KV cache and buffers need additional memory.

**Resolution:** Kernel boot parameters to expand the GTT aperture.

Current kernel cmdline (no GTT tuning):
```
iommu.passthrough=0 … amdgpu.ppfeaturemask=0xffffffff
```

Required kernel cmdline (scaled for 94 GiB system):
```
iommu=pt amdgpu.gttsize=92160 ttm.pages_limit=24117248 ttm.page_pool_size=24117248
```

| Parameter | Purpose | 128 GB doc value | Scaled for 94 GiB |
|-----------|---------|-----------------|-------------------|
| `iommu=pt` | IOMMU pass-through (see BIOS section for `amd_iommu=off` alternative) | `iommu=pt` | Same |
| `amdgpu.gttsize` | GTT aperture in MB | 126976 | 92160 (90 GiB) |
| `ttm.pages_limit` | Max TTM pages (4 KB each) | 32505856 | 24117248 (~92 GiB) |
| `ttm.page_pool_size` | TTM pool size in pages | 32505856 | 24117248 |

**NixOS config change** (in `configuration.nix` or equivalent):
```nix
boot.kernelParams = [
  "iommu=pt"
  "amdgpu.gttsize=92160"
  "ttm.pages_limit=24117248"
  "ttm.page_pool_size=24117248"
];
```

Remove the existing `iommu.passthrough=0` — the `iommu=pt` parameter replaces it.

Requires `nixos-rebuild boot && reboot`.

**Post-reboot verification:**
```sh
cat /proc/cmdline
dmesg | grep -iE 'GTT|gttsize|TTM|VRAM'
rocminfo | grep -A80 'gfx1150'
```
Expected: `amdgpu: 92160M of GTT memory ready` and Pool 1 size roughly matching the GTT aperture.

### 3. Build Environment (fixable)

ds4 builds with `make strix-halo` which invokes `hipcc` directly. On NixOS this needs a development shell.

**Dependencies needed:**
- `hipcc` (ROCm compiler) — available
- `hipblas`, `hipblaslt` — available
- `rocblas` — available
- `rocwmma` — may need internal headers not packaged by NixOS
- Standard C build tools (`cc`, `make`)

**Likely approach:** A `shell.nix` with the ROCm toolchain, then clone rocWMMA headers if the Nix package omits `rocwmma/internal/` (STRIXHALO.md notes this is common).

```nix
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    rocmPackages.hipcc
    rocmPackages.hipblas
    rocmPackages.hipblaslt
    rocmPackages.rocblas
    rocmPackages.rocwmma
    gnumake
  ];
}
```

The rocWMMA internal headers issue from STRIXHALO.md:
> No Ubuntu package currently provides those internal headers. Install a complete matching rocWMMA header tree.

If NixOS has the same gap, the fix is:
```sh
git clone --depth 1 --branch rocm-7.2.0 https://github.com/ROCm/rocWMMA.git /tmp/rocWMMA
cp -a /tmp/rocWMMA/library/include/rocwmma /path/to/include/
```

Then set `CPATH` or `C_INCLUDE_PATH` so `hipcc` finds them.

## Working Configuration

### Build

```sh
cd ~/Projects/ds4
nix-shell shell.nix --run 'make strix-halo -j$(nproc) ROCM_ARCH=gfx1150'
```

The Radeon 890M reports as `gfx1150`. The Makefile defaults to `gfx1151`
(for 8060S). Override `ROCM_ARCH` explicitly.

### Run

```sh
nix-shell shell.nix --run './ds4 --ssd-streaming --nothink -p "Hello" -n 64'
```

**SSD streaming is required.** Without it, the full model (80.76 GiB) plus
runtime buffers exceeds the 98.78 GiB GPU-visible memory (`hipMemGetInfo`).
SSD streaming keeps only hot experts in GPU memory, dropping residency from
80.76 GiB to ~74 GiB working set.

### Actual Performance (Radeon 890M, 16 CUs)

| Mode | Prefill | Generation |
|------|---------|------------|
| SSD streaming, ctx=32768, short prompt | 1.8 t/s | 3.7 t/s |

These are much lower than the STRIXHALO.md benchmarks (Strix Halo 8060S has
40 CUs vs the 890M's 16 CUs). The 890M is a Strix Point mobile GPU — expect
~5-8x slower than a full Strix Halo desktop part.

### Memory Layout

| Pool | Size | Notes |
|------|------|-------|
| System RAM | 125 GiB | After BIOS UMA → minimum |
| HSA Pool 1 (rocminfo) | 125 GiB | Fine-grained, CPU+GPU |
| GPU-visible (hipMemGetInfo) | 98.78 GiB | Limited by `amdgpu.gttsize=92160` |
| ds4 working set (SSD streaming) | 73.60 GiB | 80% of GPU-visible, cached experts only |
| Model weights (total) | 80.76 GiB | IQ2XXS quant |
| Context buffers (ctx=32768) | 1.05 GiB | Raw + compressed KV |

## Risk Notes

- **SSD streaming required.** Full model residency OOMs even with GTT expanded
  to 92 GiB. The 890M's 16 CUs also mean generation speed is ~3-4 t/s — usable
  but slow for interactive chat.
- **gfx1150 required.** Must build with `ROCM_ARCH=gfx1150`. gfx1151 binaries
  (default) segfault on the 890M.
- **Beta quality.** ds4 is weeks old. Expect rough edges.
- **ZFS + kernel 7.1.** The flake overlay patches ZFS 2.4.3's META file
  (`Linux-Maximum: 7.0` → `7.1`) and overrides the `broken` meta flag.
  ZFS 2.4.3 already includes 7.1 kernel fixes — the version cap is stale.

## References

- [STRIXHALO.md](https://github.com/antirez/ds4/blob/main/STRIXHALO.md)
- [ds4 issue #459](https://github.com/antirez/ds4/issues/459) — BIOS UMA vs context
- [Strix Halo Host System Configuration](https://deepwiki.com/kyuz0/amd-strix-halo-toolboxes/6.3-host-system-configuration)
- `flake.nix` — ZFS overlay for kernel 7.1
- `docs/dwarfstar4.md` — this document
