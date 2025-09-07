#!/usr/bin/env bash
# Install NixOS from live ISO without filling RAM:
# - Bind-mount /nix to the target disk first
# - Install directly from the live repo (not from /mnt)
set -euo pipefail

: "${HOST:=ellie}"
: "${FLAKE_DIR:=${HOME}/elixos}"   # e.g. /root/elixos on the live ISO
export NIX_CONFIG="experimental-features = nix-command flakes"

# Sanity
if ! mountpoint -q /mnt; then
  echo "❌ /mnt is not mounted. Run your disko step first." >&2
  exit 1
fi
if [ ! -d "$FLAKE_DIR" ]; then
  echo "❌ FLAKE_DIR '$FLAKE_DIR' not found (expected your repo on the live ISO)." >&2
  exit 1
fi

# (Optional) sops-nix age key into target
if [ -f /root/keys.txt ]; then
  mkdir -p /mnt/etc/sops/age
  cp -f /root/keys.txt /mnt/etc/sops/age/keys.txt
  chmod 400 /mnt/etc/sops/age/keys.txt
  echo "✅ Copied age key into /mnt/etc/sops/age/keys.txt"
fi

# Bind /nix to disk so store writes do NOT go to RAM
mkdir -p /mnt/nix
( cd /nix 2>/dev/null && tar cf - . ) | ( cd /mnt/nix && tar xpf - ) 2>/dev/null || true
mount --bind /mnt/nix /nix
mkdir -p /nix/var/nix/daemon-socket
chmod 755 /nix/var/nix/daemon-socket
echo "✅ /nix bound to /mnt/nix"

# Install directly from the live repo
echo "🚀 nixos-install --flake ${FLAKE_DIR}#${HOST}"
nixos-install --flake "${FLAKE_DIR}#${HOST}" --no-root-password

# Post-check
echo "🔎 bootctl status (target):"
nixos-enter --root /mnt -- bootctl status || true

echo "✅ Done. You can reboot."
