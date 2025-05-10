{ config, lib, pkgs, ... }:

let
  # Retrieve the global list (for example, defined in modules/common.nix)
  sshUsersRaw = config.globalSshClientUsers or [];

  # Filter only the users that actually exist in config.users.users
  sshUsers = lib.filter (user: config.users.users ? ${user}) sshUsersRaw;
in
{
  # Generate a systemd oneshot-service for each existing user
  systemd.services = lib.genAttrs sshUsers (user: {
    description = "Generate SSH public key from private key for ${user}";
    wantedBy = [ "multi-user.target" ];
    after = [ "agenix.service" ];
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

  # Ensure permissions are correct for each existing user
  systemd.tmpfiles.rules = lib.flatten (map (user: [
    "d /home/${user}/.ssh 0700 ${user} users -"
    "f /home/${user}/.ssh/id_ed25519.pub 0644 ${user} users -"
  ]) sshUsers);
}
