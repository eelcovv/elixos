{ config, pkgs, lib, ... }:

{
  # Ensure the sops age directory exists
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  # Path used by sops-nix to locate the age private key
  sops.age.keyFile = "/run/secrets.d/age-keys.txt";

  # Decrypt and install the age private key
  sops.secrets.age_key = {
    sopsFile = ../../secrets/age_key.yaml;
    name = "age-keys.txt"; # Ensures the correct output filename
    owner = "root";
    group = "root";
    mode = "0400";
  };

  # Ensure sops-install-secrets waits until the age key is available
  systemd.services."sops-install-secrets".requires = [ "sops-nix-age_key.service" ];
  systemd.services."sops-install-secrets".after = [ "sops-nix-age_key.service" ];

  # Provide SOPS_AGE_KEY_FILE environment variable explicitly (optional if keyFile is already set)
  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/run/secrets.d/age-keys.txt";
}

