{ config, lib, pkgs, ... }:

{
  options.sshUsers = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
    description = "List of users for whom SSH keys should be provisioned via SOPS.";
  };

  config =

    let
      sshUsers = config.sshUsers or [ ];

      hasSecretFile = user:
        builtins.pathExists (../../secrets + "/${config.networking.hostName}-${user}-secrets.yaml");

      validUsers = builtins.filter hasSecretFile sshUsers;

      userSecret = user: {
        "id_ed25519_${user}" = {
          sopsFile = ../../secrets/${config.networking.hostName}-${user}-secrets.yaml;
          path = "/home/${user}/.ssh/id_ed25519";
          owner = user;
          group = "users";
          mode = "0400";
          restartUnits = [ "generate-ssh-pubkey-${user}.service" ];
        };
      };

      userService = user: {
        "generate-ssh-pubkey-${user}" = {
          description = "Generate SSH public key from private key for ${user}";
          wantedBy = [ "multi-user.target" ];
          after = [ "sops-nix-id_ed25519_${user}.service" ];
          requires = [ "sops-nix-id_ed25519_${user}.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "generate-id-ed25519-pub-${user}" ''
              if [ ! -f /home/${user}/.ssh/id_ed25519.pub ]; then
                ssh-keygen -y -f /home/${user}/.ssh/id_ed25519 > /home/${user}/.ssh/id_ed25519.pub
                chown ${user}:users /home/${user}/.ssh/id_ed25519.pub
                chmod 0644 /home/${user}/.ssh/id_ed25519.pub
              fi
            '';
          };
        };
      };
    in
    {
      sops.secrets = lib.mkMerge (map userSecret validUsers);
      systemd.services = lib.mkMerge (map userService validUsers);
      systemd.tmpfiles.rules = lib.flatten (map
        (user: [
          "d /home/${user}/.ssh 0700 ${user} users -"
          "f /home/${user}/.ssh/id_ed25519.pub 0644 ${user} users -"
        ])
        validUsers);
    };
}

