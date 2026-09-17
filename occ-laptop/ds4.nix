# DwarfStar (ds4) — DeepSeek V4 Flash/PRO local inference engine.
# NOT imported by configuration.nix. Decision 2026-09: not installing ds4,
# but keep this around in case it becomes viable later.
# To enable, add ./ds4.nix to the imports in occ-laptop/configuration.nix.
# See ../docs/dwarfstar4.md for the full context (GPU aperture, quant choice,
# SSD streaming).
{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:
let
  ds4 = pkgs-unstable.stdenv.mkDerivation {
    pname = "ds4";
    version = "unstable-2026-07-14";
    src = pkgs-unstable.fetchFromGitHub {
      owner = "antirez";
      repo = "ds4";
      rev = "80ebbc396aee40eedc1d829222f3362d10fa4c6c";
      hash = "sha256-Ieuc72GHZs20ModQfnvI5Me31n4Pj+WFYtsuqaKJceo=";
    };

    nativeBuildInputs = with pkgs-unstable.rocmPackages; [
      llvm.clang clr hipblas hipblas-common hipblaslt hipcub rocblas rocprim rocwmma
    ] ++ [ pkgs-unstable.gnumake ];

    buildInputs = with pkgs-unstable.rocmPackages; [
      hipblas hipblaslt rocblas
    ];

    preBuild = ''
      export HIP_CLANG_PATH="${pkgs-unstable.rocmPackages.llvm.clang}/bin"
    '';

    buildPhase = ''
      runHook preBuild
      make strix-halo -j$NIX_BUILD_CORES ROCM_ARCH=gfx1150
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp ds4 ds4-server ds4-bench ds4-eval ds4-agent $out/bin/
      runHook postInstall
    '';

    CPATH = pkgs-unstable.lib.makeSearchPath "include" (with pkgs-unstable.rocmPackages; [
      hipblas hipblas-common hipblaslt hipcub rocblas rocprim rocwmma
    ]);
    LIBRARY_PATH = pkgs-unstable.lib.makeLibraryPath (with pkgs-unstable.rocmPackages; [
      hipblas hipblaslt rocblas
    ]);

    meta = with pkgs-unstable.lib; {
      description = "DeepSeek V4 Flash/PRO local inference engine";
      license = licenses.mit;
    };
  };
in
{
  # Expand GTT beyond 112 GiB to cross ds4's internal threshold (>= 112 GiB:
  # reserve drops from 5% to 512 MiB). Frees ~4 GiB for graph buffers,
  # potentially avoiding SSD streaming.
  # Scaled for 125 GiB system: 112 GiB GTT, ~112 GiB TTM page limit.
  boot.kernelParams = [
    "iommu=pt"
    "amdgpu.gttsize=114688"
    "ttm.pages_limit=29360128"
    "ttm.page_pool_size=29360128"
  ];

  environment.systemPackages = [ ds4 ];
}
