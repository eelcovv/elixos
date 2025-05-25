{ config, pkgs, lib, ... }:

{
  sops.defaultSopsFile = ../../secrets/singer-por-secrets.yaml;

  sops.age.keyFile = "/etc/sops/age/keys.txt";

  sops.secrets.age_key = {
    path = "/etc/sops/age/keys.txt";
    owner = "root";
    group = "root";
    mode = "0400";
  };

  sops.secrets.id_ed25519 = {
    path = "/home/por/.ssh/id_ed25519";
    owner = "por";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey-por.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /home/por/.ssh 0700 por users -"
  ];

  systemd.services.generate-ssh-pubkey-por = {
    description = "Generate SSH public key from decrypted id_ed25519";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix-id_ed25519.service" ];
    requires = [ "sops-nix-id_ed25519.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "por";
      ExecStart = "${pkgs.writeShellScript "generate-pubkey" ''
        ssh-keygen -y -f /home/por/.ssh/id_ed25519 > /home/por/.ssh/id_ed25519.pub
      ''}";
    };
  };
}
