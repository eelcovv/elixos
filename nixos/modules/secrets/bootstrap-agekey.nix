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

    ${pkgs.sops}/bin/sops -d ${../../secrets/age_key.yaml} \
      | ${pkgs.yq}/bin/yq -r .age_key > /etc/sops/age/keys.txt

    if [ ! -f /etc/sops/age/keys.txt ]; then
      echo "❌ Failed to create /etc/sops/age/keys.txt"
      exit 1
    fi

    echo "✅ /etc/sops/age/keys.txt installed"
  '';
}
