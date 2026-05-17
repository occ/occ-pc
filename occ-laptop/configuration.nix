{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}:
let
  # OpenZFS master snapshot — has Linux 7.0/7.1 compat (PRs #18435, #18471).
  # Released 2.4.1 in nixpkgs caps at kernel 6.19, but master's META declares
  # Linux-Maximum: 7.0. zfs/unstable.nix passes kernelMaxSupportedMajorMinor
  # as an inner arg of generic.nix that .override doesn't expose, so we:
  # (a) clear meta.broken (set by generic.nix from kernelMax),
  # (b) retarget the postPatch META consistency check to "7.0",
  # (c) update postPatch file paths (master moved lib/libshare/ to lib/libzfs/).
  # Drop this once OpenZFS tags 2.4.2 and nixpkgs bumps unstable.nix.
  zfsTo7 = pkg: pkg.overrideAttrs (old: {
    version = "2.4.99-unstable-2026-05-02";
    src = pkgs.fetchFromGitHub {
      owner = "openzfs";
      repo = "zfs";
      rev = "f828a80cb6e4468e7e52639fd8deccccd8c324ce";
      hash = "sha256-2tl+W8VoIYB3lx2xJa7HCWhZySxLGE5MywEjg6o6+kw=";
    };
    meta = old.meta // { broken = false; };
    postPatch = builtins.replaceStrings
      [
        "'^Linux-Maximum: *6\\.19$'"
        "./lib/libshare/os/linux/nfs.c"
        "./lib/libshare/smb.h"
      ]
      [
        "'^Linux-Maximum: *7\\.0$'"
        "./lib/libzfs/os/linux/libzfs_share_nfs.c"
        "./lib/libzfs/libzfs_share.h"
      ]
      (old.postPatch or "");
  });

in
{
  imports = [
    ./hardware-configuration.nix
    ../shared/common.nix
    inputs.nix-amd-ai.nixosModules.default
  ];

  # Linux 6.19 is EOL and removed from nixpkgs (2026-04-23). Move to 7.0.
  # Extend the kernel package set so its zfs_unstable kernel module matches
  # the userspace zfs_unstable below (NixOS asserts version equality), and
  # so its virtualbox host modules are built from the 7.2.8 modsrc.
  boot.kernelPackages = pkgs-unstable.linuxPackages_7_0.extend (_kfinal: kprev: {
    zfs_unstable = zfsTo7 kprev.zfs_unstable;
    virtualbox = kprev.virtualbox.override { virtualbox = pkgs-unstable.virtualbox; };
  });

  # Default boot.zfs.package is stable zfs (2.3.x) which caps at 6.19.
  # Use the matching zfs_unstable master snapshot.
  boot.zfs.package = zfsTo7 pkgs-unstable.zfs_unstable;

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
