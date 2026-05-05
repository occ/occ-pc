{ inputs, config, pkgs, pkgs-unstable, ... }:

{
  imports = [
    inputs.nvchad4nix.homeManagerModule
    ./configs.nix
    ./plugins.nix
  ];

  programs.nvchad = {
    enable = true;
    neovim = pkgs-unstable.neovim;
    backup = false;
    hm-activation = true;
    extraPackages = with pkgs; [
      cargo
      graphviz
      lldb
      rust-analyzer
      rustfmt
      vscode-langservers-extracted
    ];
  };

  home.packages = with pkgs; [
    wl-clipboard
  ];
}
