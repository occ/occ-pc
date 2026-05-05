{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}:
{
  programs.command-not-found.enable = true;
  programs.fish.enable = true;

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    package = pkgs-unstable.starship;

    settings =
      { }
      // builtins.fromTOML  (''
        [kubernetes]
        detect_env_vars = ["KUBECONFIG"]
        disabled = false

        [nix_shell]
        pure_msg = ""
        impure_msg = ""
      '')
      # # // {
      # #   #format = "$all";
      # #   palette = "catppuccin_mocha";
      # # }
      # # // builtins.fromTOML (
      # #   builtins.readFile (
      # #     pkgs.fetchFromGitHub {
      # #       owner = "catppuccin";
      # #       repo = "starship";
      # #       rev = "e99ba6b210c0739af2a18094024ca0bdf4bb3225";
      # #       sha256 = "sha256-1w0TJdQP5lb9jCrCmhPlSexf0PkAlcz8GBDEsRjPRns=";
      # #     }
      # #     + /themes/mocha.toml
      # #   )
      # # )
      # // builtins.fromTOML (''
      #   [aws]
      #   symbol = "  "

      #   [buf]
      #   symbol = " "

      #   [c]
      #   symbol = " "

      #   [cmake]
      #   symbol = " "

      #   [conda]
      #   symbol = " "

      #   [crystal]
      #   symbol = " "

      #   [dart]
      #   symbol = " "

      #   [directory]
      #   read_only = " 󰌾"

      #   [docker_context]
      #   symbol = " "

      #   [elixir]
      #   symbol = " "

      #   [elm]
      #   symbol = " "

      #   [fennel]
      #   symbol = " "

      #   [fossil_branch]
      #   symbol = " "

      #   [git_branch]
      #   symbol = " "

      #   [git_commit]
      #   tag_symbol = '  '

      #   [golang]
      #   symbol = " "

      #   [guix_shell]
      #   symbol = " "

      #   [haskell]
      #   symbol = " "

      #   [haxe]
      #   symbol = " "

      #   [hg_branch]
      #   symbol = " "

      #   [hostname]
      #   ssh_symbol = " "

      #   [java]
      #   symbol = " "

      #   [julia]
      #   symbol = " "

      #   [kotlin]
      #   symbol = " "

      #   [lua]
      #   symbol = " "

      #   [memory_usage]
      #   symbol = "󰍛 "

      #   [meson]
      #   symbol = "󰔷 "

      #   [nim]
      #   symbol = "󰆥 "

      #   [nix_shell]
      #   symbol = " "

      #   [nodejs]
      #   symbol = " "

      #   [ocaml]
      #   symbol = " "

      #   [os.symbols]
      #   Alpaquita = " "
      #   Alpine = " "
      #   AlmaLinux = " "
      #   Amazon = " "
      #   Android = " "
      #   Arch = " "
      #   Artix = " "
      #   CachyOS = " "
      #   CentOS = " "
      #   Debian = " "
      #   DragonFly = " "
      #   Emscripten = " "
      #   EndeavourOS = " "
      #   Fedora = " "
      #   FreeBSD = " "
      #   Garuda = "󰛓 "
      #   Gentoo = " "
      #   HardenedBSD = "󰞌 "
      #   Illumos = "󰈸 "
      #   Kali = " "
      #   Linux = " "
      #   Mabox = " "
      #   Macos = " "
      #   Manjaro = " "
      #   Mariner = " "
      #   MidnightBSD = " "
      #   Mint = " "
      #   NetBSD = " "
      #   NixOS = " "
      #   Nobara = " "
      #   OpenBSD = "󰈺 "
      #   openSUSE = " "
      #   OracleLinux = "󰌷 "
      #   Pop = " "
      #   Raspbian = " "
      #   Redhat = " "
      #   RedHatEnterprise = " "
      #   RockyLinux = " "
      #   Redox = "󰀘 "
      #   Solus = "󰠳 "
      #   SUSE = " "
      #   Ubuntu = " "
      #   Unknown = " "
      #   Void = " "
      #   Windows = "󰍲 "

      #   [package]
      #   symbol = "󰏗 "

      #   [perl]
      #   symbol = " "

      #   [php]
      #   symbol = " "

      #   [pijul_channel]
      #   symbol = " "

      #   [python]
      #   symbol = " "

      #   [rlang]
      #   symbol = "󰟔 "

      #   [ruby]
      #   symbol = " "

      #   [rust]
      #   symbol = "󱘗 "

      #   [scala]
      #   symbol = " "

      #   [swift]
      #   symbol = " "

      #   [zig]
      #   symbol = " "

      #   [gradle]
      #   symbol = " "
      # '');
      ;
  };
}
