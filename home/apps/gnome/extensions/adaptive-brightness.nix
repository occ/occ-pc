{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.adaptive-brightness ];
  my.gnome.enabledExtensions = [ "adaptive-brightness@dmy3k.github.io" ];

  dconf.settings = {
    # Tuned brightness curve (lux-bucket lower bound, lux upper bound,
    # brightness fraction). Tune in the extension's prefs if the backlight
    # feels off; the values are declarative here so a reinstall keeps them.
    "org/gnome/shell/extensions/adaptive-brightness" = {
      brightness-buckets = [
        (lib.hm.gvariant.mkTuple [ (lib.hm.gvariant.mkUint32 0) (lib.hm.gvariant.mkUint32 20) 0.15 ])
        (lib.hm.gvariant.mkTuple [ (lib.hm.gvariant.mkUint32 5) (lib.hm.gvariant.mkUint32 200) 0.25 ])
        (lib.hm.gvariant.mkTuple [ (lib.hm.gvariant.mkUint32 50) (lib.hm.gvariant.mkUint32 650) 0.5 ])
        (lib.hm.gvariant.mkTuple [ (lib.hm.gvariant.mkUint32 350) (lib.hm.gvariant.mkUint32 2000) 0.75 ])
        (lib.hm.gvariant.mkTuple [ (lib.hm.gvariant.mkUint32 1000) (lib.hm.gvariant.mkUint32 10000) 1.0 ])
      ];
    };

    # GNOME's built-in ambient brightness (gsd-power) adjusts in coarse jumps
    # and its smoothing is a hardcoded compile-time constant -- no gsettings/
    # D-Bus knob exists. adaptive-brightness replaces it with a customizable
    # curve + smooth transitions, so disable the built-in to avoid both
    # daemons fighting over the backlight.
    "org/gnome/settings-daemon/plugins/power" = {
      ambient-enabled = false;
    };
  };
}
