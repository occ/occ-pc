{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.user-themes ];
  # Shell theme name left empty: no custom shell theme, GTK stays Adwaita.
}
