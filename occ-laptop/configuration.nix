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
  ];

  # Reinstalled 2026-09 on LUKS+ext4 (was ZFS): no more ZFS/kernel version
  # coupling, track the regular latest (non-LTS) kernel from stable nixpkgs.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hibernation: resume from the LUKS swap volume (opened in initrd by
  # hardware-configuration.nix).
  boot.resumeDevice = "/dev/mapper/luks-6fa51307-36e9-48a7-89f2-daef74f125a7";

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

  environment.systemPackages = with pkgs; [
    clevis
    ddcutil

    openconnect
    gpclient
    libva-utils
  ];
}
