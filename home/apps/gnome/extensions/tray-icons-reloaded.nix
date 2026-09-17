{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.tray-icons-reloaded ];
  # tray-position/icon margins left at extension defaults; the only app entry
  # (discord, hidden=false) is the default too.
}
