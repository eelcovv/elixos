{ config, pkgs, lib, ... }:

{
  # Make sure the target folder exists
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  # The Age Private Key is in /run/secrets.d/age-keys.txt via Sops Bootstrap
  sops.age.keyFile = "/run/secrets.d/age-keys.txt";

  # Set correct Symlink for Sops to expected location
  environment.etc."sops/age/keys.txt".source = config.sops.age.keyFile;


  # For use in Systemd Services (optional, depending on your setup)
  systemd.services."sops-install-secrets".environment.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
}
