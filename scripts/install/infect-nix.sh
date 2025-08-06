#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"

if [[ -z "$HOST" ]]; then
  echo "Usage: $0 <host>"
  exit 1
fi

### 🧱 Step 1: Ensure nixbld users exist
echo "👥 Ensuring nixbld users exist..."
groupadd nixbld -g 30000 2>/dev/null || true
for i in {1..10}; do
  useradd -c "Nix build user $i" -d /var/empty -g nixbld -G nixbld -M -N -r -s "$(command -v nologin)" "nixbld$i" 2>/dev/null || true
done

### 🖇️ Step 2: Make sure resolv.conf is real
if [[ -L /etc/resolv.conf ]]; then
  echo "🔧 Making /etc/resolv.conf a real file..."
  mv -v /etc/resolv.conf /etc/resolv.conf.lnk
  cp /etc/resolv.conf.lnk /etc/resolv.conf
fi

### 🔐 Step 3: Install age key for sops-nix (if available)
if [[ -f /root/keys.txt ]]; then
  echo "🔐 Installing age key to /etc/sops/age/keys.txt..."
  mkdir -p /etc/sops/age
  cp /root/keys.txt /etc/sops/age/keys.txt
  chmod 400 /etc/sops/age/keys.txt
else
  echo "⚠️  No /root/keys.txt found — secrets depending on sops-nix may fail."
fi

### 📁 Step 4: Mark this as a NixOS system
echo "🖊️  Marking this as NixOS..."
touch /etc/NIXOS

echo etc/nixos                    >> /etc/NIXOS_LUSTRATE
echo etc/resolv.conf             >> /etc/NIXOS_LUSTRATE
echo etc/sops/age/keys.txt       >> /etc/NIXOS_LUSTRATE
echo root/.nix-defexpr/channels  >> /etc/NIXOS_LUSTRATE
(cd / && ls etc/ssh/ssh_host_*_key* 2>/dev/null || true) >> /etc/NIXOS_LUSTRATE

### 💣 Step 5: Prepare /boot for reuse (if legacy BIOS or EFI)
echo "📦 Backing up and cleaning /boot..."
rm -rf /boot.bak || true
cp -a /boot /boot.bak || true
rm -rf /boot/* || true
umount /boot || true

### ⚙️ Step 6: Run switch-to-configuration manually
echo "🎛️  Running switch-to-configuration boot..."
"$HOME/result/bin/switch-to-configuration" boot

### ✅ Done
echo "✅ System switched! Reboot when ready."

