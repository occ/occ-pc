{ lib, ... }:
{
  # Default for hosts that decrypt with the hand-copied dev age key (occ-desktop).
  # occ-laptop overrides this with a TPM-backed identity (see its configuration.nix).
  sops.age.keyFile = lib.mkDefault "/var/lib/sops-nix/occ-pc.key";
}
