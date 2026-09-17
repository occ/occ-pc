{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.tray-icons-reloaded ];
  my.gnome.enabledExtensions = [ "trayIconsReloaded@selfmade.pl" ];
  # tray-position/icon margins left at extension defaults; the only app entry
  # (discord, hidden=false) is the default too.
}
