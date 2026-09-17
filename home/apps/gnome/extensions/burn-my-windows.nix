{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.burn-my-windows ];
  my.gnome.enabledExtensions = [ "burn-my-windows@schneegans.github.com" ];
  # active-profile points at a profile file under ~/.config/burn-my-windows/
  # (user-managed, restored from backup) -- intentionally not declared.
}
