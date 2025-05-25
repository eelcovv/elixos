{ config, pkgs, lib, ... }:

{

  sops.secrets.id_ed25519_eelco = {
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey-eelco.service" ];
  };

  # mkBefore ensure that the rules of several users are merged to one list
  systemd.tmpfiles.rules = lib.mkBefore [
    "d /home/eelco/.ssh 0700 eelco users -"
  ];

  systemd.services.generate-ssh-pubkey-eelco = {
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
