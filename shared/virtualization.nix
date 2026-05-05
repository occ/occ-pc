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
}
