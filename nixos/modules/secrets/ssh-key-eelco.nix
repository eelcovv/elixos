{ config, pkgs, lib, ... }:

t
  # ensure ~/.ssh exists with correct permissions before any other rules apply
  systemd.tmpfiles.rules = lib.mkbefore [
"d /home/eelco/.ssh 0700 eelco users -"
];

# decrypt the private key via sops-nix
sops.secrets.id_ed25519_eelco = {
sopsfile = ../../secrets/singer-eelco-secrets.yaml;
path = "/home/eelco/.ssh/id_ed25519";
owner = "eelco";
group = "users";
mode = "0400";
restartunits = [ "generate-ssh-pubkey-eelco.service" ];
};

# automatically generate the corresponding public key after decryption
systemd.services.generate-ssh-pubkey-eelco = {
description = "generate ssh public key for user eelco";
wantedby = [ "multi-user.target" ];
after = [ "sops-nix-id_ed25519_eelco.service" ];
requires = [ "sops-nix-id_ed25519_eelco.service" ];
serviceconfig = {
type = "oneshot";
user = "eelco";
execstartpre = "${pkgs.coreutils}/bin/test -s /home/eelco/.ssh/id_ed25519"; # only run if private key exists and is not empty
execstart = pkgs.writeshellscript "generate-pubkey-eelco" ''
        ssh-keygen -y -f /home/eelco/.ssh/id_ed25519 > /home/eelco/.ssh/id_ed25519.pub
        chown eelco:users /home/eelco/.ssh/id_ed25519.pub
        chmod 0644 /home/eelco/.ssh/id_ed25519.pub
      '';
};
};
}
ju
