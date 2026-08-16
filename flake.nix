{
  description = "occ-laptop";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-amd-ai.url = "github:noamsto/nix-amd-ai";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
      home-manager,
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
        overlays = [
          (final: prev: {
            # Patch ZFS to accept the latest kernel (7.1). The userspace
            # package's postPatch doesn't reach the kernel module derivation,
            # so override the kernel package set's zfs_unstable directly.
            linuxPackages_latest = prev.linuxPackages_latest.extend (kfinal: kprev: {
              zfs_unstable = kprev.zfs_unstable.overrideAttrs (old: {
                postPatch = (old.postPatch or "") + ''
                  substituteInPlace META --replace-fail 'Linux-Maximum: 7.0' 'Linux-Maximum: 7.1'
                '';
                # nixpkgs still caps zfs_unstable at kernel 7.0 and marks the
                # module `broken` for 7.1. ZFS 2.4.3 already ships the 7.1
                # fixes (the cap is stale), so clear the flag here instead of
                # masking it globally via config.problems.handlers.
                meta = (old.meta or { }) // { broken = false; };
              });
            });
          })
        ];
      };
    in
    {
      homeConfigurations."occ" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit system inputs pkgs-unstable;
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
