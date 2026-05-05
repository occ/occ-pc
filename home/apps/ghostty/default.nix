{ pkgs, pkgs-unstable, ... }:
{
  home.file.".config/ghostty/config".text = ''
    bold-is-bright = true
    desktop-notifications = true
    font-family = JetBrainsMono Nerd Font Mono
    font-size = 9
    gtk-titlebar-hide-when-maximized = true

    # Claude Code Integration
    keybind = shift+enter=text:\x1b\r

    scrollback-limit = 100000000
    shell-integration = fish
    shell-integration-features = cursor,sudo,title,ssh-env
    theme = Xcode Dark hc
    window-inherit-font-size = false
  '';

  home.packages = with pkgs; [
    pkgs-unstable.ghostty
  ];
}
