{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  home.packages = with pkgs.gnomeExtensions; [
    adaptive-brightness
    blur-my-shell
    burn-my-windows
    caffeine
    clipboard-history
    desktop-cube
    hide-top-bar
    notification-banner-reloaded
    proton-vpn-button
    tray-icons-reloaded
    user-themes
  ] ++ (with pkgs; [
    flat-remix-gnome
    flat-remix-gtk
  ]);

  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        # system-monitor + status-icons (gcampax) were dropped from the
        # gnome-shell-extensions bundle and aren't installed -- enabling them
        # here just silently failed on GNOME 50. Removed.
        "desktop-cube@schneegans.github.com"
        "caffeine@patapon.info"
        "burn-my-windows@schneegans.github.com"
        "blur-my-shell@aunetx"
        "trayIconsReloaded@selfmade.pl"
        "clipboard-history@alexsaveau.dev"
        "notification-banner-reloaded@marcinjakubowski.github.com"
        "adaptive-brightness@dmy3k.github.io"
      ];
    };

    # GNOME's built-in ambient brightness (gsd-power) adjusts in coarse jumps
    # and its smoothing is a hardcoded compile-time constant -- no gsettings/
    # D-Bus knob exists. adaptive-brightness replaces it with a customizable
    # curve + smooth transitions, so disable the built-in to avoid both
    # daemons fighting over the backlight. Tune the curve in the extension's
    # own prefs (org.gnome.shell.extensions.adaptive-brightness brightness-buckets).
    "org/gnome/settings-daemon/plugins/power" = {
      ambient-enabled = false;
    };

    "org/gnome/shell/extensions/notification-banner-reloaded" = {
      always-minimized = 0;
      anchor-horizontal = 1;
      anchor-vertical = 1;
      animation-direction = 1;
    };
  };
}
