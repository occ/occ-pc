{
  description = "occ-laptop";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-amd-ai.url = "github:noamsto/nix-amd-ai";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # android-nixpkgs = {
    #   url = "github:tadfisher/android-nixpkgs";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvchad4nix = {
      url = "github:nix-community/nix4nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixos-hardware,
      # android-nixpkgs,
      home-manager,
      nvchad4nix,
      sops-nix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      homeConfigurations."occ" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit system inputs pkgs-unstable;
          # inherit android-nixpkgs;
        };
        modules = [
          ./home/home.nix
        ];
      };

      nixosConfigurations = {
        occ-desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              system
              inputs
              pkgs-unstable
              # android-nixpkgs
              nixos-hardware
              ;
          };
          modules = [
            sops-nix.nixosModules.sops
            ./occ-desktop/configuration.nix
          ];
        };

        occ-laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit
              system
              inputs
              pkgs-unstable
              # android-nixpkgs
              nixos-hardware
              ;
          };
          modules = [
            sops-nix.nixosModules.sops
            nixos-hardware.nixosModules.framework-amd-ai-300-series
            ./occ-laptop/configuration.nix
          ];
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [ pkgs.bashInteractive ];

        packages = with pkgs-unstable; [
          age
          age-plugin-tpm
          nil
          nixd
          nixfmt
          nixos-rebuild
          nixpkgs-fmt
          nixVersions.latest
          sops
          yq-go
        ];

        shellHook = ''
          export name="occ-pc"
          export SHELL=/run/current-system/sw/bin/bash
          export SOPS_AGE_KEY_FILE="$PWD/.sops/occ-pc.key"
        '';
      };
    };
}
