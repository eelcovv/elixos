{ config, lib, ... }:

let
  trustedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
  ];

  hostSpecificKeys = {
    tongfang = [];
    generic-vm = [];
  };

  host = config.networking.hostName or null;
  allKeys = trustedKeys ++ (hostSpecificKeys.${host} or []);

  tmpfilesForAuthorizedKeys = [
    "d /home/eelco/.ssh 0700 eelco users"
  ] ++ map (key:
    "f /home/eelco/.ssh/authorized_keys 0600 eelco users - ${key}"
  ) allKeys;

in {
  options = {
    eelco-authorized-keys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = allKeys;
      description = "Authorized SSH keys for user Eelco based on trusted and host-specific keys.";
    };

    # This option is used to set up tmpfiles rules for SSH authorized_keys
    # for the user Eelco. It ensures that the authorized_keys file is created
    # with the correct permissions and ownership.
    # The default value is derived from the authorized keys.
    # This approach is required because the approach with
    # users.users.eelco.openssh.authorizedKeys.keys = [ "...key..." ]; 
    # fails to create the authorized_keys file. This is a known issue 
    eelco-tmpfiles-ssh-setup = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = tmpfilesForAuthorizedKeys;
      description = "Tmpfiles rules to install authorized_keys for Eelco.";
    };
  };

  config = {
    eelco-authorized-keys = allKeys;
    eelco-tmpfiles-ssh-setup = tmpfilesForAuthorizedKeys;
  };
}

