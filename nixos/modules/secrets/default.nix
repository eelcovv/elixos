{ config, pkgs, lib, ... }:

{
  systemd.tmpfiles.rules = [
    "d /etc/sops/age 0700 root root -"
  ];

  environment.variables.SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";

  sops = {
    age.keyFile = "/etc/sops/age/keys.txt";

    secrets.age_key = {
      sopsFile = ../../secrets/age_key.yaml;
      path = "/etc/sops/age/keys.txt";
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };
}
