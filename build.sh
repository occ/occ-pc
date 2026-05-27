#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$SCRIPT_DIR"

# Prime sudo up front (also used by the preflight and the rebuild).
sudo -v

# --- sops preflight -------------------------------------------------------
# With `users.mutableUsers = false`, every account's password comes solely
# from sops (shared/users.nix). If decryption fails, the rebuild locks all
# users out of login -- recoverable only via init=/bin/sh. Refuse to deploy
# unless this host's age identity actually decrypts the login secrets, so a
# bad key fails here (still logged in) instead of at the next boot.
LOGIN_SECRETS=shared/users.sops.yaml     # backs every hashedPasswordFile

preflight_sops() {
  local sops_bin host key
  if ! sops_bin=$(command -v sops); then
    echo "ERROR: 'sops' not on PATH -- run from the dev shell (direnv / nix develop)." >&2
    return 1
  fi
  host=$(hostname)

  case "$host" in
    occ-laptop)
      # TPM-backed identity, materialised from this committed copy at boot.
      # Decrypts only on this machine's TPM; occ is in the 'tss' group.
      key="$SCRIPT_DIR/occ-laptop/tpm-identity.txt"
      if ! command -v age-plugin-tpm >/dev/null; then
        echo "ERROR: 'age-plugin-tpm' not on PATH -- run from the dev shell." >&2
        return 1
      fi
      if [[ ! -f "$key" ]]; then
        echo "ERROR: TPM identity missing at $key." >&2
        return 1
      fi
      if ! env "SOPS_AGE_KEY_FILE=$key" "$sops_bin" -d "$LOGIN_SECRETS" >/dev/null 2>&1; then
        echo "ERROR: this machine's TPM cannot decrypt $LOGIN_SECRETS via $key." >&2
        echo "       (TPM cleared / identity regenerated?) Fix before rebuilding or you'll be locked out." >&2
        return 1
      fi
      echo "sops preflight OK: TPM decrypts $LOGIN_SECRETS"
      ;;
    *)
      # Hand-copied dev age key (root-owned).
      key=/var/lib/sops-nix/occ-pc.key       # must match shared/sops.nix
      if ! sudo test -f "$key"; then
        echo "ERROR: sops age key missing at $key -> lockout. Copy it before rebuilding." >&2
        return 1
      fi
      if ! sudo env "SOPS_AGE_KEY_FILE=$key" "$sops_bin" -d "$LOGIN_SECRETS" >/dev/null 2>&1; then
        echo "ERROR: $key cannot decrypt $LOGIN_SECRETS -> lockout. Fix before rebuilding." >&2
        return 1
      fi
      echo "sops preflight OK: $key decrypts $LOGIN_SECRETS"
      ;;
  esac
}

if [[ "${1:-}" == "--update" ]]; then
  nix flake update
  git commit flake.lock -m "Update flake references" || echo "No changes to commit"
  git pull --rebase
  git push || echo "No changes to push"
fi

preflight_sops

echo "*** System ***"
# `switch` (not `boot`): activate now so any failure surfaces while we're
# still logged in, instead of being deferred to a boot we can't recover from.
sudo nixos-rebuild switch --flake "$SCRIPT_DIR"

echo
echo "*** Home ***"
home-manager switch --flake "$SCRIPT_DIR" -b backup
