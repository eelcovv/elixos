{ config, lib, pkgs, ... }:

let
  sshUsersRaw = config.globalSshClientUsers or [];

  # Filter alleen bestaande users
  sshUsers = lib.filter (user: config.users.users ? ${user}) sshUsersRaw;
in
{
  systemd.services = lib.genAttrs sshUsers (user: {
    description = "Generate SSH public key from private key for ${user}";
    wantedBy = [ "multi-user.target" ];
    after = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = ''
        if [ -f /home/${user}/.ssh/id_ed25519 ]; then
          ${pkgs.openssh}/bin/ssh-keygen -y -f /home/${user}/.ssh/id_ed25519 > /home/${user}/.ssh/id_ed25519.pub
        fi
      '';
      ExecStartPre = "! test -s /home/${user}/.ssh/id_ed25519.pub";
    };
  });

  systemd.tmpfiles.rules = sshUsers
    ++ [
      # Zorg dat .ssh directory bestaat
      "d /home/eelco/.ssh 0700 eelco users -"
      "f /home/eelco/.ssh/id_ed25519.pub 0644 eelco users -"
    ];
}