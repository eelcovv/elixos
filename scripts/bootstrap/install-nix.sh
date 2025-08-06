#!/usr/bin/env bash
set -euo pipefail

echo "📁 Creating /nix directory..."
mkdir -m 0755 -p /nix && chown root /nix

echo "👷 Creating nixbld build users..."
groupadd nixbld -g 30000 || true
for i in $(seq 1 10); do
  useradd -c "Nix build user $i" -d /var/empty -g nixbld -G nixbld \
          -M -N -r -s /usr/sbin/nologin nixbld$i || true
done

echo "⬇️ Downloading Nix binary tarball..."
curl -L https://releases.nixos.org/nix/nix-2.30.2/nix-2.30.2-x86_64-linux.tar.xz -o nix.tar.xz

echo "📦 Extracting and installing Nix..."
tar -xf nix.tar.xz
cd nix-2.30.2-x86_64-linux && ./install
