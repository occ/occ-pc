{ lib, ... }:
# Durable GNOME preferences recovered from the pre-reinstall dconf database
# (restored 2026-09-17). Only real preferences live here -- window sizes,
# portal file-chooser paths, notification per-app state, timestamps and other
# session state were deliberately left out.
{
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      accent-color = "yellow";
      color-scheme = "prefer-dark";
      icon-theme = "MoreWaita"; # packaged in ../gnome-theme
      show-battery-percentage = true;
      text-scaling-factor = 0.85;
    };

    "org/gnome/desktop/background" = {
      picture-options = "zoom";
      # ~/.config/background is a user-managed JPEG (restored from backup),
      # not tracked in this repo.
      picture-uri = "file:///home/occ/.config/background";
      picture-uri-dark = "file:///home/occ/.config/background";
      primary-color = "#241f31";
    };

    "org/gnome/desktop/wm/preferences" = {
      action-middle-click-titlebar = "none";
      button-layout = "appmenu:close";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [ (lib.hm.gvariant.mkTuple [ "xkb" "us" ]) ];
      xkb-options = [
        "terminate:ctrl_alt_bksp"
        "lv3:rwin_switch"
        "compose:ralt"
      ];
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      edge-scrolling-enabled = false;
      natural-scroll = false;
      tap-to-click = true;
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };

    "org/gnome/desktop/privacy" = {
      recent-files-max-age = -1; # keep recent files forever
    };

    "org/gnome/desktop/search-providers" = {
      disabled = [
        "org.gnome.Epiphany.desktop"
        "org.gnome.Calendar.desktop"
        "org.gnome.clocks.desktop"
        "org.gnome.seahorse.Application.desktop"
      ];
    };

    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "google-chrome.desktop"
        "code.desktop"
        "org.gnome.Geary.desktop"
        "com.mitchellh.ghostty.desktop"
        "freelens.desktop"
        "virtualbox.desktop"
        "org.gnome.Nautilus.desktop"
      ];
    };

    "org/gnome/nautilus/preferences" = {
      default-folder-viewer = "list-view";
    };

    "org/gnome/Console" = {
      custom-font = "JetBrainsMono Nerd Font 12";
      use-system-font = false;
    };

    "org/freedesktop/tracker/miner/files" = {
      # stock XDG dirs plus Projects
      index-recursive-directories = [
        "&DESKTOP"
        "&DOCUMENTS"
        "&MUSIC"
        "&PICTURES"
        "&VIDEOS"
        "&DOWNLOAD"
        "/home/occ/Projects"
      ];
    };

    "org/gtk/settings/file-chooser" = {
      sort-column = "modified";
      sort-directories-first = true;
      sort-order = "descending";
    };

    "org/gtk/gtk4/settings/file-chooser" = {
      sort-column = "modified";
      sort-directories-first = true;
      sort-order = "descending";
    };
  };
}
