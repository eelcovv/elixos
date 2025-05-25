{ config, lib, pkgs, ... }:

let
  # List of users die een SSH client key hebben
  sshUsersRaw = config.globalSshClientUsers or [];

  # Filter alleen de users die werkelijk bestaan
  sshUsers = lib.filter (user: config.users.users ? ${user}) sshUsersRaw;
in
{
  # Genereer een systemd oneshot-service voor elke gebruiker
  systemd.services = lib.genAttrs sshUsers (user: {
    description = "Generate SSH public key from private key for ${user}";
    after = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = pkgs.writeShellScript "generate-id-ed25519-pub-${user}" ''
        if [ -f /home/${user}/.ssh/id_ed25519 ]; then
          ${pkgs.openssh}/bin/ssh-keygen -y -f /home/${user}/.ssh/id_ed25519 > /home/${user}/.ssh/id_ed25519.pub
        fi
      '';
    };
  });

  # Zorg dat .ssh-map bestaat en juiste permissies heeft
  systemd.tmpfiles.rules = lib.flatten (map (user: [
    "d /home/${user}/.ssh 0700 ${user} users -"
    "f /home/${user}/.ssh/id_ed25519.pub 0644 ${user} users -"
  ]) sshUsers);
}

