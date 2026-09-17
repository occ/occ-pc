{ pkgs, ... }:
{
  home.packages = [ pkgs.gnomeExtensions.burn-my-windows ];
  # active-profile points at a profile file under ~/.config/burn-my-windows/
  # (user-managed, restored from backup) -- intentionally not declared.
}
