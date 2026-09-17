{
  config,
  pkgs,
  pkgs-unstable,
  # android-nixpkgs,
  ...
}:
let
  kubectl-wrapped = pkgs.writeShellScriptBin "kubectl" ''
    exec env KUBECTL_COMMAND=${pkgs-unstable.kubectl}/bin/kubectl ${pkgs-unstable.kubecolor}/bin/kubecolor "$@"
  '';
in
{
  nixpkgs.overlays = [
    # android-nixpkgs.overlays.default
  ];
  imports = [
    ./apps/atuin
    ./apps/browser-router
    ./apps/claude-code
    ./apps/claude-desktop
    ./apps/ghostty
    ./apps/gnome
    ./apps/gnome-theme
    ./apps/lens
    ./apps/starship
    ./apps/vscode
    ./settings/espresso-display.nix
    ./settings/vrr.nix
    # android-nixpkgs.hmModule
    # {
    #   android-sdk.enable = true;

    #   # Optional; default path is "~/.local/share/android".
    #   android-sdk.path = "${config.home.homeDirectory}/.android/sdk";

    #   android-sdk.packages =
    #     sdk: with sdk; [
    #       # android-studio
    #       build-tools-35-0-0
    #       build-tools-34-0-0
    #       cmdline-tools-latest
    #       emulator
    #       platforms-android-35
    #       platforms-android-34
    #       sources-android-35
    #       sources-android-34
    #       ndk-26-1-10909125
    #       system-images-android-35-google-apis-arm64-v8a
    #       platform-tools
    #       cmake-3-22-1
    #     ];
    # }
  ];

  home.enableNixpkgsReleaseCheck = false;
  home.homeDirectory = "/home/occ";
  home.username = "occ";
  home.packages = with pkgs; [
    appimage-run
    pkgs-unstable.aptakube
    dig
    discord
    firefox
    fragments
    freelens-bin
    gh
    git
    gnome-boxes
    google-chrome
    kubectl-wrapped
    pkgs-unstable.kubectl-cnpg
    pkgs-unstable.kubelogin-oidc
    pkgs-unstable.libation
    libreoffice
    mc
    newsflash
    numbat
    resources
    signal-desktop
    # stockfish
    vlc
    pkgs-unstable.zed-editor
  ];

  home.sessionVariables = {
    CHROME_EXECUTABLE = "google-chrome-stable";
    DIRENV_LOG_FORMAT = "";
    # NIXOS_OZONE_WL = "1";
  };

  home.shellAliases = {
    "libation_sync" =
      "rsync -avz --info=progress2 -e \"ssh\" --rsync-path=\"sudo rsync\" ~/Libation/Books/ occ-nas:/vol0/pvc-a1ec8d5a-a6ff-4b0a-8f9a-1d327fbdb42b/";
  };

  home.stateVersion = "26.05";

  programs = {
    # Work links open in the fleetdriver.com Chrome profile, the rest in Firefox.
    browser-router = {
      enable = true;
      default = "${pkgs.firefox}/bin/firefox";
      rules = [
        {
          hosts = [
            "fd.dev"
            "*.fd.dev"
            "fleetdriver.*"
            "*.fleetdriver.*"
          ];
          # Chrome wants the profile directory, not its display name; the
          # mapping is `profile.info_cache` in ~/.config/google-chrome/Local State.
          browser = ''${pkgs.google-chrome}/bin/google-chrome-stable --profile-directory="Profile 7"'';
        }
      ];
    };

    # OMP loads audio backends dynamically, outside nix-ld's library path.
    fish.functions.omp = ''
      set -lx LD_LIBRARY_PATH ${
        pkgs.lib.makeLibraryPath [
          pkgs.libpulseaudio
          pkgs.alsa-lib
        ]
      } $LD_LIBRARY_PATH
      command omp $argv
    '';

    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      silent = true;
      config.whitelist.prefix = [ "/home/occ/Projects/FleetDriver/fleetdriver/" ];
    };

    git = {
      enable = true;
      settings = {
        user = {
          name = "Onur Cakmak";
          email = "occ@occ.me";
        };
      };
    };

    home-manager.enable = true;
  };

  xdg.enable = true;
}
