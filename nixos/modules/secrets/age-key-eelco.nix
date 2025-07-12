{ config, pkgs, lib, ... }:

{
  sops.secrets.age_key_user = {
    sopsFile = ../../secrets/age_key.yaml;
    path = "/home/eelco/.config/sops/age/keys.txt";
    owner = "eelco";
    group = "users";
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d /home/eelco/.config 0755 eelco users -"
    "d /home/eelco/.config/sops 0755 eelco users -"
    "d /home/eelco/.config/sops/age 0700 eelco users -"
  ];
}