{ config, pkgs, lib, ... }:

{
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  systemd.user.extraEnv = {
    SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
  };

  sops = {
    defaultSopsFile = ../../secrets/age_key.yaml;
    age.keyFile = "/etc/sops/age/keys.txt";
    secrets.age_key = {
      path = "/etc/sops/age/keys.txt";
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
