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
in
{
  options.eelco-authorized-keys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = allKeys;
    description = "Authorized SSH keys for user Eelco based on trusted and host-specific keys.";
  };

  config.eelco-authorized-keys = builtins.trace allKeys allKeys;
}
