{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.blur-my-shell ];
  my.gnome.enabledExtensions = [ "blur-my-shell@aunetx" ];
}
