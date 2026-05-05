{
  config,
  lib,
  pkgs,
  ...
}:
{
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
    ];
  };

  services.printing = {
    enable = true;
    drivers = with pkgs; [ epson-escpr2 ];
    browsed.enable = false;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
}
