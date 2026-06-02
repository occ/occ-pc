{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    inputs.nix-amd-ai.nixosModules.default
  ];

  # Linux 6.19 is EOL and removed from nixpkgs (2026-04-23). Pinned 25.11's
  # linuxPackages_7_0 has a broken zfs_unstable (2.4.0) and only an older
  # virtualbox module, so take the kernel set from unstable: it ships
  # zfs_unstable 2.4.2 (7.0-compatible) and virtualbox-modules 7.2.8.
  boot.kernelPackages = pkgs-unstable.linuxPackages_7_0;

  # Default boot.zfs.package is stable zfs (2.3.x) which caps at 6.19.
  # Match the kernel's zfs_unstable 2.4.2 (NixOS asserts version equality).
  boot.zfs.package = pkgs-unstable.zfs_unstable;

  nixpkgs.overlays = [
    (final: prev: {
      virtualbox = pkgs-unstable.virtualbox;
      # nix-amd-ai's amd-npu module references pkgs.stable-diffusion-cpp
      # directly (enableImageGen defaults true), but that package only
      # exists in nixos-unstable, not our pinned nixos-25.11. Pull it from
      # unstable so the lemonade image-gen recipes resolve.
      stable-diffusion-cpp = pkgs-unstable.stable-diffusion-cpp;
    })
  ];

  networking.hostName = "occ-laptop";
  networking.networkmanager.enable = true;
  # WireGuard support is built into NetworkManager; only OpenVPN needs a plugin.
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  security.tpm2.enable = true;

  # --- sops decryption via a TPM-backed age identity ----------------------
  # Replaces the hand-copied /var/lib/sops-nix/occ-pc.key. The identity only
  # unseals on this machine's TPM (no PCR binding, no PIN), so it's safe to
  # ship in the closure: ./tpm-identity.txt is materialised into tmpfs at boot,
  # before sops needs it. The dev age key stays a recipient (.sops.yaml) for
  # offline recovery / re-keying if the TPM is ever cleared.
  sops.age = {
    keyFile = "/run/sops-tpm-identity.txt";
    plugins = [ pkgs.age-plugin-tpm ];
  };

  # userborn (not the legacy users activation script) moves user + secret setup
  # into systemd units, so the early password-secret install can be ordered
  # after the TPM device is ready. systemd-sysusers would force
  # mutableUsers = true (sops-nix assertion); userborn supports immutable users.
  services.userborn.enable = true;

  systemd.services =
    let
      # Refuse to decrypt until /dev/tpmrm0 exists, or the TPM unseal fails and
      # every account is locked out. The for-users unit runs very early
      # (DefaultDependencies=no, before sysinit) -- do NOT order against the
      # dev-tpmrm0.device unit there: it isn't active that early and systemd
      # blocks forever ("Expecting device /dev/tpmrm0..."), hanging the boot.
      # devtmpfs creates the node as soon as the tpm driver binds, and this unit
      # runs as root (no tss-group udev rule needed), so polling the node is
      # enough.
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
      # Materialise the committed TPM identity into tmpfs before either sops
      # install unit reads sops.age.keyFile.
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
      # 'amdvlk' has been removed since it was deprecated by AMD. Its replacement, RADV, is enabled by default.
      # amdvlk
    ];
  };

  # DDC/CI brightness control for the external Espresso display (ddcutil over i2c).
  hardware.i2c.enable = true;

  # Skip hid-generic driver for MX Ergo so logitech-hidpp binds directly,
  # avoiding a double driver handoff race that delays input after BT reconnect
  services.udev.extraRules = ''
    ACTION=="add", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="b01d", ENV{HID_GENERIC}="0"
  '';

  hardware.amd-npu = {
    enable = true;
    enableFastFlowLM = true;
    enableLemonade = true;
    # Vulkan (RADV) offload for the Radeon 890M (gfx1150). Installs
    # llama-cpp-vulkan ahead of the CPU build on PATH, so llama-server and
    # lemonade's llama.cpp backend run on the iGPU instead of CPU/BLAS.
    enableVulkan = true;
    lemonade.user = "occ";
  };

  environment.systemPackages = with pkgs; [
    clevis
    ddcutil
    # intel-gpu-tools
    libva-utils
  ];
}
