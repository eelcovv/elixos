#!/usr/bin/env bash
set -euo pipefail

HOST="$1"

echo "🔐 Checking for age key..."
if [[ -f /root/keys.txt ]]; then
  echo "📁 Installing age key to /etc/sops/age/keys.txt..."
  mkdir -p /mnt/etc/sops/age
  cp /root/keys.txt /mnt/etc/sops/age/keys.txt
  chmod 400 /mnt/etc/sops/age/keys.txt
else
  echo "⚠️  Warning: /root/keys.txt not found. Skipping age key installation."
  echo "    → Secrets may fail to decrypt if needed by this configuration."
fi

echo "🚀 Installing system..."
/root/result/bin/switch-to-configuration boot

echo "💾 Installing GRUB..."
# Alleen nodig bij BIOS-boot (zoals jij nu hebt):
nixos-install --system /root/result --no-root-passwd

echo "✅ System installed for $HOST"


