{
  config,
  lib,
  pkgs,
  ...
}:
{
  services = {
    libinput.enable = true;

    desktopManager.gnome = {
      enable = true;
      # Enable fractional scaling
      # extraGSettingsOverridePackages = [ pkgs.gnome.mutter ];
      # extraGSettingsOverrides = ''
      #   [org.gnome.mutter]
      #   experimental-features=['scale-monitor-framebuffer']
      # '';
    };

    displayManager.gdm = {
      enable = true;
      # GNOME 50 dropped X11; GDM is always Wayland now, so the `wayland`
      # option was removed (any definition trips an assertion).
    };

    gnome.gnome-keyring.enable = true;

    xserver = {
      enable = true;

      excludePackages = with pkgs; [
        xterm
      ];

      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
}
