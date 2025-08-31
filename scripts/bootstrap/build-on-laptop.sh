# === 0) Safety ===
set -euo pipefail

# (Optioneel) als je SOPS/age gebruikt:
if [ -f /root/keys.txt ]; then
    mkdir -p /mnt/etc/sops/age
    cp -f /root/keys.txt /mnt/etc/sops/age/keys.txt
    chmod 400 /mnt/etc/sops/age/keys.txt
fi

# === 1) Zorg dat /nix NIET in RAM hangt ===
mkdir -p /mnt/nix
# Kopieer eventuele bestaande inhoud van /nix naar disk (tar werkt zelfs als rsync ontbreekt)
( cd /nix 2>/dev/null && tar cf - . ) | ( cd /mnt/nix && tar xpf - ) 2>/dev/null || true
# Bind nu de disk terug op /nix
mount --bind /mnt/nix /nix

# Socket-dir (soms nodig, harmless otherwise)
mkdir -p /nix/var/nix/daemon-socket
chmod 755 /nix/var/nix/daemon-socket

# === 2) Nix features altijd aan in deze sessie ===
export NIX_CONFIG="experimental-features = nix-command flakes"

# === 3) Bouw je systeem rechtstreeks naar /mnt ===
# Pas 'singer' en repo-pad aan als jouw setup anders is.
cd /mnt/home/elixos
nix build .#nixosConfigurations.singer.config.system.build.toplevel --out-link /mnt/result

# === 4) Installeer ===
nixos-install --system /mnt/result --no-root-passwd

echo "✅ Klaar. Je kunt nu rebooten."
