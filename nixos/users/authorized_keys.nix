# This option is used to set up tmpfiles rules for SSH authorized_keys
# for the user Eelco. It ensures that the authorized_keys file is created
# with the correct permissions and ownership.
# The default value is derived from the authorized keys.
# This approach is required because the approach with
# users.users.eelco.openssh.authorizedKeys.keys = [ "...key..." ]; 
# fails to create the authorized_keys file. This is a known issue 
{ config
, lib
, ...
}:

let
  perUserKeys = {
    eelco = {
      trusted = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
      ];
      hostSpecific = {
        tongfang = [ ];
        generic-vm = [ ];
      };
    };

    deploy = {
      trusted = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDeployKey deploy@somewhere"
      ];
      hostSpecific = {
        contabo = [ ];
      };
    };
  };

  host = config.networking.hostName or null;

  usersWithKeys = lib.attrNames perUserKeys;

  buildKeyList = user:
    let
      base = perUserKeys.${user}.trusted or [ ];
      hostKeys = perUserKeys.${user}.hostSpecific.${host} or [ ];
    in
    base ++ hostKeys;

  allKeysPerUser = lib.genAttrs usersWithKeys buildKeyList;

  tmpfilesForUser = user:
    let keys = allKeysPerUser.${user};
    in [
      "d /home/${user}/.ssh 0700 ${user} users"
    ] ++ map (key: "f /home/${user}/.ssh/authorized_keys 0600 ${user} users - ${key}") keys;

  tmpfilesAll = lib.flatten (map tmpfilesForUser usersWithKeys);

in
{
  options = {
    authorizedKeys.perUser = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = allKeysPerUser;
      description = "SSH keys per user, host-dependent.";
    };

    authorizedKeys.tmpfilesRules = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = tmpfilesAll;
      description = "All tmpfiles rules to create .ssh/authorized_keys files.";
    };
  };

  config = {
    authorizedKeys.perUser = allKeysPerUser;
    authorizedKeys.tmpfilesRules = tmpfilesAll;
  };
}

