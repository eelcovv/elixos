#!/usr/bin/env bash
set -euo pipefail

HOST="$1"

echo "📦 Building system for $HOST..."
cd /root/elixos
nix build .#nixosConfigurations."$HOST".config.system.build.toplevel --out-link /root/result
