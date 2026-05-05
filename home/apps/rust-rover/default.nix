{ inputs, config, pkgs, ... }:

{
  imports = [
  ];

  home.packages = with pkgs; [
    jetbrains.rust-rover
  ];

  home.sessionVariables = {
    RUSTROVER_PROPERTIES = "${config.home.homeDirectory}/.config/rust-rover/idea.properties";
  };

  home.file.".config/rust-rover/idea.properties".text = "idea.filewatcher.executable.path = ${pkgs.fsnotifier}/bin/fsnotifier";
}
