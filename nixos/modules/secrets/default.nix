{ config, pkgs, lib, ... }:

{
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  sops.secrets.age_key = {
    sopsFile = ../../secrets/singer-eelco-secrets.yaml;
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
