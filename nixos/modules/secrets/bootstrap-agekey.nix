{ config, pkgs, lib, ... }:

{
  # This encrypts the age key itself and stores it in a expected place
  system.activationScripts.installAgeKey.text = ''
    echo "🔐 Installing /etc/sops/age/keys.txt using in-store sops"
    umask 077
    mkdir -p /etc/sops/age
    ${pkgs.sops}/bin/sops -d ${../../secrets/age_key.yaml} | ${pkgs.yq}/bin/yq -r .age_key > /etc/sops/age/keys.txt
  '';
}
