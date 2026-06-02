{
  config,
  lib,
  pkgs,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.05";

  sops.secrets.nix_cache_priv_key.sopsFile = ./common.sops.yaml;

  imports = [
    ./boot.nix
    ./epson-et-3950.nix
    ./fonts.nix
    ./fix-gnome-login.nix
    ./hosts.nix
    ./locale.nix
    ./sops.nix
    ./users.nix
    ./virtualization.nix
    ./x.nix
  ];

  environment.systemPackages = with pkgs; [
    btop
    docker-compose
    file
    htop
    killall
    libsecret
    nano
    pciutils
    powertop
    python3
    ripgrep
    tree
    unzip
    usbutils
    wget
    wireguard-tools
    zip
  ];

  # GnuPG
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  services.pcscd.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.pulseaudio.enable = false;

  networking.enableIPv6 = false;

  networking.firewall = {
    enable = false;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    optimise.automatic = true;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      require-sigs = true;
      secret-key-files = [
        config.sops.secrets.nix_cache_priv_key.path
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "occ-server.home:SO6f5yGVjTz4eMzrYlAlfNwB2T6ma7LUHn0fqAGig7U="
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];
    };
  };

  programs = {
    bash.enable = true;
    fish = {
      enable = true;
      # interactiveShellInit = ''
      #   set fish_greeting # Disable greeting
      # '';
    };
    geary.enable = true;
    java.enable = true;
    nix-ld.enable = true;
    steam.enable = true;
  };

  services.gnome.evolution-data-server.enable = true;
  services.printing.enable = true;
}
