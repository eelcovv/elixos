{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [ sops yq ];

  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"

  ];

  system.activationScripts.installAgeKey.text = ''
  echo "🔐 Installing /etc/sops/age/keys.txt using local identity"

  export HOME="/root"
  export SOPS_AGE_KEY_FILE="/root/.config/sops/age/keys.txt"

  if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
    echo "❌ SOPS_AGE_KEY_FILE ($SOPS_AGE_KEY_FILE) does not exist!"
    exit 1
  fi

  echo "📁 Using SOPS_AGE_KEY_FILE at: $SOPS_AGE_KEY_FILE"
  mkdir -p /etc/sops/age

  echo "🔎 Attempting decryption of age_key.yaml..."
  DECRYPTED="$(${pkgs.sops}/bin/sops -d ${../../secrets/age_key.yaml})" || {
    echo "❌ SOPS decryption failed"
    exit 1
  }

  echo "🔎 Extracting age_key manually..."
  echo "$DECRYPTED" | ${pkgs.gnused}/bin/sed -n '/^age_key: *|/,/^sops:/p' | \
    ${pkgs.gnused}/bin/sed '/^sops:/d' | \
    ${pkgs.gnused}/bin/sed 's/^  //' > /etc/sops/age/keys.txt

  if [ ! -s /etc/sops/age/keys.txt ]; then
    echo "❌ /etc/sops/age/keys.txt is missing or empty"
    exit 1
  fi

  echo "✅ /etc/sops/age/keys.txt installed"
'';



}
