{ inputs, config, pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs; [
    protonvpn-gui
  ];
}
