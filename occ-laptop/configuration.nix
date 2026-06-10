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

  # Linux 6.19 is EOL and removed from nixpkgs (2026-04-23). Pinned 26.05's
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
    })
  ];

  networking.hostName = "occ-laptop";
  networking.networkmanager.enable = true;
  # WireGuard support is built into NetworkManager; OpenVPN and OpenConnect protocols need plugins.
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
    networkmanager-openconnect
  ];

  # --- AX210 (iwlwifi) suspend/resume workaround --------------------------
  # The AX210 firmware ty-a0-gf-a0-89.ucode intermittently SYSASSERTs across
  # s2idle suspend/resume ("Failed to start RT ucode: -110"): on wake WiFi is
  # dead, NetworkManager wedges in uninterruptible sleep so the box can't
  # re-suspend, and Bluetooth (same AX210 combo chip) drops with it -- only a
  # reboot recovers. Firmware can't fix this: kernel 7.0's iwlwifi hard-requires
  # exactly -89 (it won't fall back to an older file -- verified: removing -89
  # left "no suitable firmware found"), and -89 is already the newest build.
  # So instead reload the driver around sleep: tear it down before suspend and
  # bring it back on resume, so the firmware re-inits from scratch instead of
  # resuming into a wedged state. The reload re-probes the PCI device, which
  # re-creates the netdev (NetworkManager reconnects) and reloads BT-shared
  # state cleanly. `|| true` on unload so a hiccup never blocks suspend. Drop
  # this once a fixed firmware/kernel lands. Symptom in journal: ADVANCED_SYSASSERT.
  #
  # NB: unload with a SINGLE arg (iwlwifi). NixOS ships a custom modprobe
  # `remove iwlwifi` command that already tears down the whole stack
  # (rmmod iwlmvm+iwlwifi, then `modprobe -r mac80211`). Passing `iwlmvm iwlwifi`
  # fires that command twice -- the second run hits an empty stack, so its
  # `xargs rmmod` runs with no module name, errors, and aborts the *entire*
  # unload (verified: modules stayed loaded). `modprobe -r iwlwifi` alone is the
  # correct invocation; `modprobe iwlwifi` on resume pulls iwlmvm + mac80211.
  powerManagement.powerDownCommands = ''
    ${pkgs.kmod}/bin/modprobe -r iwlwifi || true
  '';
  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/modprobe iwlwifi
  '';

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
    # ROCm kept as a fallback and for HIP ecosystem tooling (rocminfo,
    # profilers, HIP apps). gfx1150 is targeted natively, so no
    # HSA_OVERRIDE_GFX_VERSION needed. Note: llama-cpp-rocm is declared
    # before llama-cpp-vulkan in the module's systemPackages, so the bare
    # `llama-server` on PATH resolves to the ROCm build; lemonade still
    # routes per-backend via its *_ROCM_BIN / *_VULKAN_BIN env hooks.
    # Per nix-amd-ai's own gfx1150 benchmarks, Vulkan beats ROCm for
    # decode/prefill, so inference still prefers Vulkan.
    enableROCm = true;
    lemonade.user = "occ";
  };

  environment.systemPackages = with pkgs; [
    clevis
    ddcutil
    openconnect
    gpclient
    # intel-gpu-tools
    libva-utils
  ];
}
