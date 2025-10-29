{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./default.nix
    ./pypi.nix
  ];

  elx.pypi.user = "eelco";


  sops.secrets.id_ed25519_eelco_tongfang = {
    sopsFile = ../../secrets/id_ed25519_eelco_tongfang.yaml;
    key = "id_ed25519_eelco_tongfang";
    path = "/home/eelco/.ssh/id_ed25519";
    owner = "eelco";
    group = "users";
    mode = "0400";
    restartUnits = ["generate-ssh-pubkey.service"];
  };

  # Make sure that ~/.ssh exists and has the right permissions
  systemd.tmpfiles.rules = lib.mkBefore [
    "d /home/eelco/.ssh 0700 eelco users -"
  ];

  # Automatically generate the .pub file after decryption of id_ed25519
  systemd.services.generate-ssh-pubkey = {
    description = "Generate SSH public key from decrypted id_ed25519";
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "eelco";
      ExecStartPre = "${pkgs.coreutils}/bin/test -s /home/eelco/.ssh/id_ed25519";
      ExecStart = "${pkgs.writeShellScript "generate-pubkey" ''
        set -e
        ${pkgs.openssh}/bin/ssh-keygen -y -f /home/eelco/.ssh/id_ed25519 > /home/eelco/.ssh/id_ed25519.pub
        chown eelco:users /home/eelco/.ssh/id_ed25519.pub
        chmod 0644 /home/eelco/.ssh/id_ed25519.pub
      ''}";
    };
  };
}
