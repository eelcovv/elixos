{ config, pkgs, lib, ... }:

{
  sops.defaultSopsFile = ../../secrets/singer-eelco-secrets.yaml;

  sops.age.keyFile = "/etc/sops/age/keys.txt";

  sops.secrets.age_key = {
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
