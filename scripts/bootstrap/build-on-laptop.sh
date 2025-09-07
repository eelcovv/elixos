#!/usr/bin/env bash
# Robust build/install for a laptop from the live ISO
# - Does NOT assume the repo is already copied into /mnt
# - Installs directly from the live user's repo path (default: ~/elixos)
# - Binds /nix to disk to avoid RAM pressure
# - Copies age key if present
set -euo pipefail

# ---- Config (override via env if needed) ----
: "${HOST:=ellie}"          # target host in your flake
: "${FLAKE_DIR:=~/elixos}"  # repo path on the live ISO user
export NIX_CONFIG="experimental-features = nix-command flakes"

# ---- Sanity checks ----
if ! mountpoint -q /mnt; then
  echo "❌ /mnt is not mounted. Run your disko step first." >&2
  exit 1
fi

if [ ! -d "$FLAKE_DIR" ]; then
  echo "❌ FLAKE_DIR '$FLAKE_DIR' not found. Did you run 'just bootstrap-base' and 'just clone-repo'?" >&2
  exit 1
fi

# ---- (Optional) SOPS/age key into target ----
if [ -f /root/keys.txt ]; then
  mkdir -p /mnt/etc/sops/age
  cp -f /root/keys.txt /mnt/etc/sops/age/keys.txt
  chmod 400 /mnt/etc/sops/age/keys.txt
  echo "✅ Copied age key into /mnt/etc/sops/age/keys.txt"
fi

# ---- Ensure /nix is backed by disk, not tmpfs ----
mkdir -p /mnt/nix
# Copy existing /nix content if present (tar works even without rsync)
( cd /nix 2>/dev/null && tar cf - . ) | ( cd /mnt/nix && tar xpf - ) 2>/dev/null || true
mount --bind /mnt/nix /nix
mkdir -p /nix/var/nix/daemon-socket
chmod 755 /nix/var/nix/daemon-socket
echo "✅ /nix bound to disk"

# ---- Install directly from the flake (simplest & fast) ----
echo "🚀 Running nixos-install from flake '$FLAKE_DIR' for host '#$HOST'…"
nixos-install --flake "$FLAKE_DIR#$HOST" --no-root-password

# If you prefer the explicit build → install flow, uncomment:
# echo "🔨 Building system derivation to /mnt/result…"
# nix build "$FLAKE_DIR#nixosConfigurations.${HOST}.config.system.build.toplevel" --out-link /mnt/result
# echo "💾 Installing /mnt/result…"
# nixos-install --system /mnt/result --no-root-passwd

# ---- Post-check: systemd-boot in the target ESP ----
echo "🔎 bootctl status (target ESP):"
nixos-enter --root /mnt -- bootctl status || true

echo "✅ Done. You can reboot."

