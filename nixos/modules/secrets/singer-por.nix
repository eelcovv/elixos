{ config, pkgs, lib, ... }:

{

  # Ensure ~/.ssh exists before anything else touches it
  systemd.tmpfiles.rules = lib.mkBefore [
    "d /home/por/.ssh 0700 por users -"
  ];

  # Decrypt the private SSH key into the standard OpenSSH location
  sops.secrets.id_ed25519_por = {
    sopsFile = ../../secrets/id_ed25519_por_singer.yaml;
    key = "id_ed25519_por_singer";
    path = "/home/por/.ssh/id_ed25519";
    owner = "por";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey-por.service" ];
  };

  # Automatically generate .pub key once private key is available
  systemd.services.generate-ssh-pubkey-por = {
    description = "Generate SSH public key for user por";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix-id_ed25519_por.service" ];
    requires = [ "sops-nix-id_ed25519_por.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "por";
      ExecStartPre = "${pkgs.coreutils}/bin/test -s /home/por/.ssh/id_ed25519";
      ExecStart = pkgs.writeShellScript "generate-pubkey-por" ''
        ssh-keygen -y -f /home/por/.ssh/id_ed25519 > /home/por/.ssh/id_ed25519.pub
        chown por:users /home/por/.ssh/id_ed25519.pub
        chmod 0644 /home/por/.ssh/id_ed25519.pub
      '';
    };
  };
}

