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
    after = [ "agenix.service" "default.target" ];
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
  systemd.tmpfiles.rules = [
    # Create a directory
    "d /home/eelco/.ssh 0700 eelco users -"
    # Symlink to the decrypted Age-secret
    "L+ /home/eelco/.ssh/id_ed25519 - - - - /run/agenix/ssh_key_generic_vm_eelco"
    # Create public key from private key
    "f /home/eelco/.ssh/id_ed25519.pub 0644 eelco users -"
  ];

}
