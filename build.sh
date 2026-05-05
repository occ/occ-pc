#!/usr/bin/env bash

set -e

sudo echo

SCRIPT_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

cd "$SCRIPT_DIR"

if [[ "$1" == "--update" ]]; then
  nix flake update
  git commit flake.lock -m "Update flake references" || echo "No changes to commit"
  git pull --rebase
  git push || echo "No changes to push"
fi


echo "*** System ***"
sudo nixos-rebuild boot --flake $SCRIPT_DIR

echo
echo "*** Home ***"
home-manager switch --flake $SCRIPT_DIR -b backup
