{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.hide-top-bar ];
  # Installed but currently disabled in dconf's disabled-extensions.
}
