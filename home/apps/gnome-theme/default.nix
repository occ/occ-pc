{ config, pkgs, pkgs-unstable, lib, ... }:
{
  home.packages = with pkgs; [
    flat-remix-gnome
    flat-remix-gtk
    gnome-themes-extra
    gtk-engine-murrine
    morewaita-icon-theme
    sassc
  ];
}
