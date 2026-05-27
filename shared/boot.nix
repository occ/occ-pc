{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.enable = true;
    # Show the systemd-boot menu for 5s so a bad generation can always be
    # escaped by selecting the previous one.
    loader.timeout = 5;
    plymouth.enable = true;
    tmp.cleanOnBoot = true;
  };
}
