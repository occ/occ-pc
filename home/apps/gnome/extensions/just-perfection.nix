{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.just-perfection ];
  my.gnome.enabledExtensions = [ "just-perfection-desktop@just-perfection" ];

  dconf.settings."org/gnome/shell/extensions/just-perfection" = {
    notification-banner-position = 2;
  };
}
