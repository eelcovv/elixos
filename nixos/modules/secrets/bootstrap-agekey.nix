{ config, pkgs, lib, ... }:

{
  system.activationScripts.installAgeKey.text = ''
    echo "🔐 Installing /etc/sops/age/keys.txt using local identity"
    umask 077
    mkdir -p /etc/sops/age

    HOME=/root \
    SOPS_AGE_KEY_FILE=/root/.config/sops/age/keys.txt \
      ${pkgs.sops}/bin/sops -d ${../../secrets/age_key.yaml} |
      ${pkgs.yq}/bin/yq -r .age_key > /etc/sops/age/keys.txt
  '';
}
