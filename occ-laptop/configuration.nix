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

  # Skip hid-generic driver for MX Ergo so logitech-hidpp binds directly,
  # avoiding a double driver handoff race that delays input after BT reconnect
  services.udev.extraRules = ''
    ACTION=="add", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="b01d", ENV{HID_GENERIC}="0"
  '';

  hardware.amd-npu = {
    enable = true;
    enableFastFlowLM = true;
    enableLemonade = true;
    lemonade.user = "occ";
  };

  environment.systemPackages = with pkgs; [
    clevis
    # intel-gpu-tools
    libva-utils
  ];
}
