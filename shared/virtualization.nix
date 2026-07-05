{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Enable KVM and libvirt
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true; # TPM emulation
    };
  };

  virtualisation.docker.enable = true;

  systemd.user.services.docker.environment = let
    MB = 1024*1024;
  in {
    BUILDKIT_STEP_LOG_MAX_SIZE = toString (1024 * MB);
    BUILDKIT_STEP_LOG_MAX_SPEED = toString (10 * MB);  # per second
  };

  virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;

  # VirtualBox >= 6.1.28 restricts host-only adapter IPs to 192.168.56.0/21
  # unless /etc/vbox/networks.conf allows more. FleetDriver's dev harness
  # (Phase 2 of docs/plans/class-e-240-address-plan.md in the fleetdriver
  # repo) uses 240.0.2.1 for the host-only management net, which VirtualBox
  # otherwise rejects with E_ACCESSDENIED. Keep 192.168.56.0/21 allowed
  # during the transition.
  environment.etc."vbox/networks.conf".text = "* 240.0.0.0/8 192.168.56.0/21";
}
