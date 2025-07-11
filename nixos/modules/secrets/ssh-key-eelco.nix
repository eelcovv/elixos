{ config, pkgs, lib, ... }:

{
  # Ensure ~/.ssh exists with correct permissions before any other rules apply
  systemd.tmpfiles.rules = lib.mkBefore [
    "d /home/eelco/.ssh 0700 eelco users -"
  ];

  # Decrypt the private key via sops-nix
  sops.secrets.id_ed25519_eelco = {
    sopsFile = ../../secrets/singer-eelco-secrets.yaml;
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
    restartUnits = [ "generate-ssh-pubkey-eelco.service" ];
  };

  # Automatically generate the corresponding public key after decryption
  systemd.services.generate-ssh-pubkey-eelco = {
    description = "Generate SSH public key for user eelco";
    wantedBy = [ "multi-user.target" ];
    after = [ "sops-nix-id_ed25519_eelco.service" ];
    requires = [ "sops-nix-id_ed25519_eelco.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "eelco";
      ExecStartPre = "${pkgs.coreutils}/bin/test -s /home/eelco/.ssh/id_ed25519";
      ExecStart = pkgs.writeShellScript "generate-pubkey-eelco" ''
        ssh-keygen -y -f /home/eelco/.ssh/id_ed25519 > /home/eelco/.ssh/id_ed25519.pub
        chown eelco:users /home/eelco/.ssh/id_ed25519.pub
        chmod 0644 /home/eelco/.ssh/id_ed25519.pub
      '';
    };
  };
}

