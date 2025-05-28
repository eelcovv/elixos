{ config, pkgs, lib, ... }:

{
  sops.secrets.id_ed25519_eelco = {
    sopsFile = ../../secrets/singer-eelco-secrets.yaml;
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey-eelco.service" ];
  };

  systemd.tmpfiles.rules = lib.mkBefore [
    "d /home/eelco/.ssh 0700 eelco users -"
  ];

  systemd.services.generate-ssh-pubkey-eelco = {
    description = "Generate SSH public key from decrypted id_ed25519";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix-id_ed25519_eelco.service" ];
    requires = [ "sops-nix-id_ed25519_eelco.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "generate-pubkey" ''
        if [ ! -f /home/eelco/.ssh/id_ed25519.pub ]; then
          ssh-keygen -y -f /home/eelco/.ssh/id_ed25519 > /home/eelco/.ssh/id_ed25519.pub
          chown eelco:users /home/eelco/.ssh/id_ed25519.pub
          chmod 0644 /home/eelco/.ssh/id_ed25519.pub
        fi
      '';
    };
  };
}
