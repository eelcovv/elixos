#!/usr/bin/env bash
set -euo pipefail

HOST="$1"
echo "📦 Building system for $HOST..."

nix --extra-experimental-features "nix-command flakes" \
  build ".#nixosConfigurations.${HOST}.config.system.build.toplevel" \
  --out-link "result-${HOST}"

