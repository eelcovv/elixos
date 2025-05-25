{ config, pkgs, lib, ... }:

{


  sops.secrets.id_ed25519 = {
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey.service" ];
  };

  # Zorg dat ~/.ssh bestaat
  systemd.tmpfiles.rules = [
    "d /home/eelco/.ssh 0700 eelco users -"
  ];

  # Genereer automatisch de .pub na decryptie van id_ed25519
  systemd.services.generate-ssh-pubkey = {
    description = "Generate SSH public key from decrypted id_ed25519";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix-id_ed25519.service" ];
    requires = [ "sops-nix-id_ed25519.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "eelco";
      ExecStart = "${pkgs.writeShellScript "generate-pubkey" ''
        ssh-keygen -y -f /home/eelco/.ssh/id_ed25519 > /home/eelco/.ssh/id_ed25519.pub
      ''}";
    };
  };
}
