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
          description = "Generate SSH public key for ${user}";
          wantedBy = [ "multi-user.target" ];
          after = [ "sops-nix-id_ed25519_${user}.service" ];
          requires = [ "sops-nix-id_ed25519_${user}.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = pkgs.writeShellScript "wait-for-secret-${user}" ''
              set -eu
              echo "[INFO] Waiting for private key /home/${user}/.ssh/id_ed25519 to be ready..."
              for i in $(seq 1 10); do
                if [ -s /home/${user}/.ssh/id_ed25519 ]; then
                  echo "[INFO] Private key is available."
                  exit 0
                fi
                echo "[WARN] Private key not ready yet, retrying in 1s..."
                sleep 1
              done
              echo "[ERROR] Timeout waiting for id_ed25519 to be available"
              exit 1
            '';
            ExecStart = pkgs.writeShellScript "generate-id-ed25519-pub-${user}" ''
              set -eu
              echo "[INFO] Checking for ~/.ssh/id_ed25519.pub for user '${user}'"
              if [ ! -f /home/${user}/.ssh/id_ed25519.pub ]; then
                echo "[INFO] Generating public key for ${user}..."
                ssh-keygen -y -f /home/${user}/.ssh/id_ed25519 > /home/${user}/.ssh/id_ed25519.pub
                chown ${user}:users /home/${user}/.ssh/id_ed25519.pub
                chmod 0644 /home/${user}/.ssh/id_ed25519.pub
              else
                echo "[INFO] Public key for ${user} already exists, skipping."
              fi
            '';
          };
        };
      };

    in {
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
