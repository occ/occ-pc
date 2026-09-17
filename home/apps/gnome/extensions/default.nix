{ config, lib, ... }:
# One module per extension, colocating its package, dconf prefs, and its
# enabled-extensions entry. Each module appends its UUID to
# `my.gnome.enabledExtensions` (a listOf str, so contributions merge across
# modules); this file only aggregates them into the single dconf
# enabled-extensions list -- a raw dconf list value would conflict, not merge,
# if written from more than one module.
{
  imports = [
    ./adaptive-brightness.nix
    ./blur-my-shell.nix
    ./burn-my-windows.nix
    ./caffeine.nix
    ./clipboard-history.nix
    ./desktop-cube.nix
    ./just-perfection.nix
    ./kde-origin-name.nix
    ./tray-icons-reloaded.nix
    ./user-themes.nix
  ];

  options.my.gnome.enabledExtensions = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
    description = ''
      GNOME Shell extension UUIDs to enable. Each extension module appends its
      own; aggregated here into org/gnome/shell enabled-extensions.
    '';
  };

  config.dconf.settings."org/gnome/shell".enabled-extensions =
    config.my.gnome.enabledExtensions;
}
