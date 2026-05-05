# This is a workaround for a bug in Gnome which makes login start an empty session
{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services = {
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
  };
}
