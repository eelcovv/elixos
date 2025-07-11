{ config, pkgs, lib, ... }:

{
  # Zorg dat de map bestaat
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  # Zet de age key op de juiste plek
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  sops.secrets.age_key = {
    sopsFile = ../../secrets/age_key.yaml;
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
    earlySecret = true;
  };

  # Zodat systemd environment variabelen deze kunnen vinden
  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
}
