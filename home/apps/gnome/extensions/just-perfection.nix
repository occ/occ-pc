{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.just-perfection ];

  dconf.settings."org/gnome/shell/extensions/just-perfection" = {
    notification-banner-position = 2; # bottom-right instead of top-center
  };
}
