{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
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
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    inputs.nix-amd-ai.nixosModules.default
  ];

  # Track nixpkgs-unstable's latest kernel (currently 7.1) + ZFS 2.4.3:
  # ZFS META caps at 7.0 but the code already has 7.1 support (see the
  # flake overlay patching Linux-Maximum to 7.1).
  boot.kernelPackages = pkgs-unstable.linuxPackages_latest;

  # Default boot.zfs.package is stable zfs (2.3.x) which caps at 6.19.
  # Match the kernel with zfs_unstable 2.4.3 (NixOS asserts version equality).
  # The flake overlay patches META to accept kernel 7.1.
  boot.zfs.package = pkgs-unstable.zfs_unstable;
  # 26.11 default: refuse to force-import the root pool to avoid data loss
  # if it is in use by another system (e.g. after an unclean shutdown).
  boot.zfs.forceImportRoot = false;
  # ds4 (DwarfStar) — expand GTT beyond 112 GiB to cross ds4's internal
  # threshold (>= 112 GiB: reserve drops from 5% to 512 MiB). This frees
  # ~4 GiB for graph buffers, potentially avoiding SSD streaming.
  # Scaled for 125 GiB system: 112 GiB GTT, ~112 GiB TTM page limit.
  boot.kernelParams = [
    "iommu=pt"
    "amdgpu.gttsize=114688"
    "ttm.pages_limit=29360128"
    "ttm.page_pool_size=29360128"
  ];

  nixpkgs.overlays = [
    (final: prev: {
      virtualbox = pkgs-unstable.virtualbox;
    })
  ];

  networking.hostName = "occ-laptop";
  networking.networkmanager.enable = true;
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
    networkmanager-openconnect
  ];

  powerManagement.powerDownCommands = ''
    ${pkgs.kmod}/bin/modprobe -r iwlwifi || true
  '';
  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/modprobe iwlwifi
  '';

  security.tpm2.enable = true;

  sops.age = {
    keyFile = "/run/sops-tpm-identity.txt";
    plugins = [ pkgs.age-plugin-tpm ];
  };

  services.userborn.enable = true;

  systemd.services =
    let
      waitForTpm.serviceConfig.ExecStartPre = pkgs.writeShellScript "wait-for-tpm" ''
        for _ in $(${pkgs.coreutils}/bin/seq 1 100); do
          [ -e /dev/tpmrm0 ] && exit 0
          ${pkgs.coreutils}/bin/sleep 0.1
        done
        echo "wait-for-tpm: /dev/tpmrm0 never appeared" >&2
        exit 1
      '';
    in
    {
      provide-sops-tpm-identity = {
        before = [
          "sops-install-secrets.service"
          "sops-install-secrets-for-users.service"
        ];
        requiredBy = [
          "sops-install-secrets.service"
          "sops-install-secrets-for-users.service"
        ];
        unitConfig.DefaultDependencies = false;
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/install -m600 -o root -g root ${./tpm-identity.txt} /run/sops-tpm-identity.txt";
        };
      };
      sops-install-secrets = waitForTpm;
      sops-install-secrets-for-users = waitForTpm;
    };

  services = {
    flatpak.enable = true;
    smartd.enable = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau
    ];
  };

  hardware.i2c.enable = true;

  services.udev.extraRules = ''
    ACTION=="add", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="b01d", ENV{HID_GENERIC}="0"
  '';

  hardware.amd-npu = {
    enable = true;
    enableFastFlowLM = true;
    enableLemonade = true;
    enableVulkan = true;
    enableROCm = true;
    lemonade.user = "occ";
  };

  environment.systemPackages = with pkgs; [
    amd-debug-tools
    clevis
    ddcutil
    ds4
    openconnect
    gpclient
    libva-utils
  ];
}
