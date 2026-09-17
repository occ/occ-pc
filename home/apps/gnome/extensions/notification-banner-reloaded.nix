{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.notification-banner-reloaded ];

  dconf.settings."org/gnome/shell/extensions/notification-banner-reloaded" = {
    always-minimized = 0;
    anchor-horizontal = 1;
    anchor-vertical = 1;
    animation-direction = 1;
    padding-horizontal = 1;
    padding-vertical = 1;
  };
}
