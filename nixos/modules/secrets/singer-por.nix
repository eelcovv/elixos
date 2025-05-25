{ config, pkgs, lib, ... }:

{
  sops.secrets.id_ed25519_por = {
    sopsFile = ../../secrets/singer-por-secrets.yaml;
    path = "/home/por/.ssh/id_ed25519";
    owner = "por";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey-por.service" ];
  };

  systemd.tmpfiles.rules = lib.mkBefore [
    "d /home/por/.ssh 0700 por users -"
  ];

  systemd.services.generate-ssh-pubkey-por = {
    description = "Generate SSH public key from decrypted id_ed25519";
    serviceConfig = {
      Type = "oneshot";
      User = "por";
      ExecStart = "${pkgs.writeShellScript "generate-pubkey-por" ''
        #!/bin/sh
        [ -f /home/por/.ssh/id_ed25519.pub ] || \
          ssh-keygen -y -f /home/por/.ssh/id_ed25519 > /home/por/.ssh/id_ed25519.pub
      ''}";
    };
  };
}

