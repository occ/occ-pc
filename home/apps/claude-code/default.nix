{ pkgs, ... }:
{
  programs.fish.shellInit = ''
    fish_add_path --prepend --global $HOME/.local/bin
  '';

  home.packages = with pkgs; [
    sox
  ];
}
