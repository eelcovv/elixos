{ config, pkgs, lib, ... }:

{
  sops.defaultSopsFile = ../../secrets/generic-vm-eelco-secrets.yaml;


  sops.age.keyFile = "/etc/sops/age/keys.txt";

  sops.secrets.age_key = {
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.id_ed25519 = {
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
  };

  systemd.services.generate-ssh-pubkey = {
    description = "Generate SSH public key from decrypted id_ed25519";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix.service" ];
    requires = [ "sops-nix.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "eelco";
      ExecStart = "${pkgs.writeShellScript "generate-pubkey" ''
  ssh-keygen -y -f /home/eelco/.ssh/id_ed25519 > /home/eelco/.ssh/id_ed25519.pub
''}";


    };
  };

  systemd.tmpfiles.rules = [
    "d /home/eelco/.ssh 0700 eelco users -"
  ];
}
