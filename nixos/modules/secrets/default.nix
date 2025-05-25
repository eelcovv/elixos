{ config, pkgs, lib, ... }:

{
  # Zorg dat de doelmap bestaat
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  # Laat Nix weten waar de age key naartoe moet
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  # SOPS_AGE_KEY_FILE beschikbaar maken voor systemd services
  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";

  # Deze decrypt de age_key.yaml → /etc/sops/age/keys.txt
  sops.secrets.age_key = {
    sopsFile = ../../secrets/age_key.yaml;
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
