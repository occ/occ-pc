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

## Verification Steps

After all blockers are resolved:

1. **Clone and build:**
   ```sh
   git clone https://github.com/antirez/ds4
   cd ds4
   make strix-halo -j$(nproc)
   ```

2. **Download the model:**
   ```sh
   ./download_model.sh q2-imatrix
   ```
   (Set `DS4_GGUF_DIR` first if using external storage.)

3. **Smoke test:**
   ```sh
   ./ds4 -p "Hello, who are you?" -n 128
   ```

4. **Performance expectation** (from STRIXHALO.md benchmarks — M3 Max 128 GB as rough analog):
   - Prefill: ~50-90 t/s (short prompt)
   - Generation: ~20-35 t/s

## Risk Notes

- **RAM headroom is tight.** 94 GiB total, model ~81 GiB weights, OS + buffers ~5-8 GiB, KV cache variable. At long context lengths (32K+), the KV cache may push into swap or trigger OOM. SSD streaming (`--ssd` flag) can help offload KV cache to disk.
- **gfx1150 vs gfx1151.** The ds4 Makefile targets `gfx1151` (Radeon 8060S in Framework Desktop). Your GPU reports as gfx1150 (890M). These are the same ISA family — ROCm `--offload-arch=gfx1151` binaries should work on gfx1150, but it's worth verifying. If not, changing `ROCM_ARCH ?= gfx1151` to `gfx1150` in the Makefile may be needed.
- **Beta quality.** ds4 is days/weeks old. The author calls it beta. Expect rough edges.
- **Kernel crash risk.** The README warns that macOS CPU path crashes the kernel on current macOS versions. This is irrelevant on Linux/ROCm, but worth knowing the codebase is young.

- [STRIXHALO.md](https://github.com/antirez/ds4/blob/main/STRIXHALO.md) — official Strix Halo setup guide
- [ds4 issue #459](https://github.com/antirez/ds4/issues/459) — BIOS UMA reservation vs. usable context (counter-intuitive)
- [Strix Halo Host System Configuration](https://deepwiki.com/kyuz0/amd-strix-halo-toolboxes/6.3-host-system-configuration) — community kernel param and BIOS reference
- [download_model.sh](https://github.com/antirez/ds4/blob/main/download_model.sh) — model download script
- Model repo: `https://huggingface.co/antirez/deepseek-v4-gguf`
