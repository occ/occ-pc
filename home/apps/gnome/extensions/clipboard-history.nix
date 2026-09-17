{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.clipboard-history ];
  my.gnome.enabledExtensions = [ "clipboard-history@alexsaveau.dev" ];
}
