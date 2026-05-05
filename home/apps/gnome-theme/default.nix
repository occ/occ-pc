{ config, pkgs, pkgs-unstable, lib, ... }:
{
  home.packages = with pkgs; [
    gnome-themes-extra
    gtk-engine-murrine
    morewaita-icon-theme
    sassc
  ];
}
