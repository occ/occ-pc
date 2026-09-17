{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.user-themes ];
  my.gnome.enabledExtensions = [ "user-theme@gnome-shell-extensions.gcampax.github.com" ];
  # Shell theme name left empty: no custom shell theme, GTK stays Adwaita.
  # Note: system-monitor + status-icons (gcampax) were dropped from the
  # gnome-shell-extensions bundle and aren't installed -- enabling them just
  # silently failed on GNOME 50, so they're not in enabledExtensions.
}
