{ config, pkgs, lib, ... }:

{
  # Locatie van age sleutel
  sops.age.keyFile = "/etc/sops/age/keys.txt";

  # Zorg dat ~/.ssh bestaat
  systemd.tmpfiles.rules = [
    "d /home/eelco/.ssh 0700 eelco users -"
  ];

  # Decrypt de private key via SOPS
  sops.secrets.id_ed25519_eelco = {
    sopsFile = ../../secrets/singer-id_ed25519.yaml;
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey-eelco.service" ];
  };

  # Genereer de .pub file automatisch na decrypt
  systemd.services.generate-ssh-pubkey-eelco = {
    description = "Generate SSH public key for user eelco";
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
