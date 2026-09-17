{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.caffeine ];
  my.gnome.enabledExtensions = [ "caffeine@patapon.info" ];

  dconf.settings."org/gnome/shell/extensions/caffeine" = {
    cli-toggle = true; # `gnome-extensions prefs`-independent D-Bus toggle
  };
}
