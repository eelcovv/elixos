{ config, pkgs, lib, ... }:

{
  system.activationScripts.installAgeKey.text = ''
    echo "🔐 Installing /etc/sops/age/keys.txt using local identity"
    umask 077
    mkdir -p /etc/sops/age

    if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
      echo "❌ SOPS_AGE_KEY_FILE ($SOPS_AGE_KEY_FILE) does not exist!"
      exit 1
    fi

    echo "📁 Using SOPS_AGE_KEY_FILE at: $SOPS_AGE_KEY_FILE"

    HOME=/root \
    SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
      ${pkgs.sops}/bin/sops -d ${../../secrets/age_key.yaml} |
      ${pkgs.yq}/bin/yq -r .age_key > /etc/sops/age/keys.txt
  '';
}
