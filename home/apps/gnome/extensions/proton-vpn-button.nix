{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.proton-vpn-button ];
  # Installed but not in enabled-extensions -- toggle on deliberately.
}
