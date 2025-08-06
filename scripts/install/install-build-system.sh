#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"

echo "🔐 Checking for age key..."
if [[ -f /root/keys.txt ]]; then
  echo "📁 Installing age key to /etc/sops/age/keys.txt..."
  mkdir -p /mnt/etc/sops/age
  cp /root/keys.txt /etc/sops/age/keys.txt
  chmod 400 /mnt/etc/sops/age/keys.txt
else
  echo "⚠️  Warning: /root/keys.txt not found. Skipping age key installation."
  echo "    → Secrets may fail to decrypt if needed by this configuration."
fi

echo "👥 Ensuring nixbld users exist..."
groupadd nixbld -g 30000 2>/dev/null || true
for i in {1..10}; do
  useradd -c "Nix build user $i" -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(which nologin)" "nixbld$i" 2>/dev/null || true
done

echo "📥 Sourcing nix profile to fix \$PATH..."
if [[ -f /etc/profile.d/nix.sh ]]; then
  source /etc/profile.d/nix.sh
else
  echo "⚠️  Could not source system profile — PATH may be incomplete."
fi

echo "🚀 Installing system..."
nix --extra-experimental-features 'nix-command flakes' \
  run github:NixOS/nixpkgs/25.05#nixos-install -- \
  --system "$HOME/result" --no-root-passwd

echo "✅ System installed"
echo "📌 You can now reboot into your new NixOS system."
echo "🔄 After reboot, run 'nixos-rebuild switch' to reapply or update the config."
