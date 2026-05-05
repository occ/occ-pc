{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  home.packages = with pkgs.gnomeExtensions; [
    blur-my-shell
    burn-my-windows
    caffeine
    clipboard-history
    desktop-cube
    hide-top-bar
    notification-banner-reloaded
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
        "system-monitor@gnome-shell-extensions.gcampax.github.com" 
        "status-icons@gnome-shell-extensions.gcampax.github.com"
        "desktop-cube@schneegans.github.com"
        "caffeine@patapon.info"
        "burn-my-windows@schneegans.github.com"
        "blur-my-shell@aunetx"
        "trayIconsReloaded@selfmade.pl"
        "clipboard-history@alexsaveau.dev"
        "notification-banner-reloaded@marcinjakubowski.github.com"
      ];
    };

    "org/gnome/shell/extensions/notification-banner-reloaded" = {
      always-minimized = 0;
      anchor-horizontal = 1;
      anchor-vertical = 1;
      animation-direction = 1;
    };
  };
}
