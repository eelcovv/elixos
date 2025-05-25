{ config, pkgs, lib, ... }:

{
  sops.secrets.age_key = {
    sopsFile = ../../secrets/age_key.yaml;
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.age.keyFile = "/etc/sops/age/keys.txt"; # This creates the symbolic link to your sops age keys.txt
}
