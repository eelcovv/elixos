  config = let
    sshUsers = config.sshUsers or [];

    hasSecretFile = user:
      builtins.pathExists (../../secrets + "/${config.networking.hostName}-${user}-secrets.yaml");

    validUsers = builtins.filter hasSecretFile sshUsers;

    tracedValidUsers = builtins.trace "validUsers = ${builtins.toString validUsers}" validUsers;

    userSecret = user: {
      "id_ed25519_${user}" = {
        sopsFile = ../../secrets/${config.networking.hostName}-${user}-secrets.yaml;
        path = "/home/${user}/.ssh/id_ed25519";
        owner = user;
        group = "users";
        mode = "0400";
        restartUnits = ["generate-ssh-pubkey-${user}.service"];
      };
    };

    userService = user: {
      "generate-ssh-pubkey-${user}" = {
        ...
      };
    };
  in {
    sops.secrets = lib.mkMerge (map userSecret tracedValidUsers);

    systemd.services = lib.mkMerge (map userService tracedValidUsers);

    systemd.tmpfiles.rules = lib.flatten (map
      (user: [
        "d /home/${user}/.ssh 0700 ${user} users -"
        "f /home/${user}/.ssh/id_ed25519.pub 0644 ${user} users -"
      ])
      tracedValidUsers);
  };

