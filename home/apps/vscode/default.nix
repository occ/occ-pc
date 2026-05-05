{ inputs, config, pkgs, pkgs-unstable, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs-unstable.vscode;
    # package = (pkgs.vscode.override{ isInsiders = true; }).overrideAttrs (oldAttrs: rec {
    #   src = (builtins.fetchTarball {
    #     url = "https://update.code.visualstudio.com/latest/linux-x64/insider";
    #     sha256 = "0ikynk2vvnwxmxn4h3nxsk2sgd5r6hy27sh08d6bwq5ns74yy2lb";
    #   });
    #   version = "latest";
    # });
  };
}
