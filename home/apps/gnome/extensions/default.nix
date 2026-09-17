{ ... }:
# One module per extension, colocating its package with its dconf prefs.
# This file only aggregates: it imports every extension module and owns the
# single enabled-extensions list (a dconf list can't be split across modules).
{
  imports = [
    ./adaptive-brightness.nix
    ./blur-my-shell.nix
    ./burn-my-windows.nix
    ./caffeine.nix
    ./clipboard-history.nix
    ./desktop-cube.nix
    ./hide-top-bar.nix
    ./just-perfection.nix
    ./kde-origin-name.nix
    ./notification-banner-reloaded.nix
    ./proton-vpn-button.nix
    ./tray-icons-reloaded.nix
    ./user-themes.nix
  ];

  dconf.settings."org/gnome/shell" = {
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
      "just-perfection-desktop@just-perfection"
      "kde-origin-name@occ.me"
    ];
  };
}
