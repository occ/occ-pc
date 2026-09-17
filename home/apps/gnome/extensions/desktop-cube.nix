{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.desktop-cube ];
  my.gnome.enabledExtensions = [ "desktop-cube@schneegans.github.com" ];
}
