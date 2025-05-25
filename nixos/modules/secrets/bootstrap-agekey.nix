{ pkgs, lib, ... }:

{
  # This encrypts the age key itself and stores it in a expected place
  system.activationScripts.installAgeKey.text = ''
    echo "🔐 Installing /etc/sops/age/keys.txt..."
    umask 077
    mkdir -p /etc/sops/age
    sops -d ${../../secrets/age_key.yaml} | yq -r .age_key > /etc/sops/age/keys.txt
  '';
}
