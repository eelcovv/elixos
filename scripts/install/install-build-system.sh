#!/usr/bin/env bash
set -euo pipefail

echo "🔐 Checking for age key..."
if [ ! -f /etc/sops/age/keys.txt ]; then
  echo "📁 Installing age key to /etc/sops/age/keys.txt..."
  mkdir -p /etc/sops/age
  cp ~/keys.txt /etc/sops/age/keys.txt
  chmod 400 /etc/sops/age/keys.txt
fi

echo "👥 Adding nixbld users..."
groupadd nixbld -g 30000 || true
for i in {1..10}; do
  useradd -c "Nix build user $i" -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(which nologin)" "nixbld$i" || true
done

echo "📥 Registering result as system profile..."
nix-env --set \
  -p /nix/var/nix/profiles/system \
  -f $HOME/result

echo "🧹 Cleaning up old default profiles..."
rm -fv /nix/var/nix/profiles/default* || true

echo "📥 Fixing /etc/resolv.conf if symlinked..."
if [ -L /etc/resolv.conf ]; then
  mv -v /etc/resolv.conf /etc/resolv.conf.lnk
  cat /etc/resolv.conf.lnk > /etc/resolv.conf
fi

echo "📥 Sourcing nix profile..."
if [ -f /nix/var/nix/profiles/system/etc/profile.d/nix.sh ]; then
  source /nix/var/nix/profiles/system/etc/profile.d/nix.sh
else
  echo "⚠️  nix.sh not found — PATH may be incomplete"
fi

echo "🚀 Installing system..."
/nix/var/nix/profiles/system/bin/nixos-install --system $HOME/result --no-root-passwd

echo "🔁 Running switch-to-configuration boot..."
/nix/var/nix/profiles/system/bin/switch-to-configuration boot

echo "✅ System installation complete!"

