{ config, pkgs, lib, ... }:

{
  # Make sure the target folder exists
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  # Let Nix know where the Age Key should go
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  # Declarative decrypts from the Age Key itself
  sops.secrets.age_key = {
    sopsFile = ../../secrets/age_key.yaml;
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # For use in Systemd Services (optional, depending on your setup)
  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
}
