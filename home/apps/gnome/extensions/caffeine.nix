{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.caffeine ];

  dconf.settings."org/gnome/shell/extensions/caffeine" = {
    cli-toggle = true; # `gnome-extensions prefs`-independent D-Bus toggle
  };
}
