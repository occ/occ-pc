{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  imports = [
    ./extensions.nix
  ];

  gtk = {
    enable = true;
  };

  home.packages = with pkgs; [
    gimp
    gnome-chess
    gnome-tweaks
  ];
}
