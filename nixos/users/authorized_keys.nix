{ config, lib, ... }:

let
  trustedKeys = [
    # Global trusted keys
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC3+DBjLHGlQinS0+qeC5JgFakaPFc+b+btlZABO7ZX6 eelco@tongfang"
    # Possible more keys, if you want to run VM on other machines too
  ];

  hostSpecificKeys = {
    tongfang = [
      # Extra keys only for Tongfang
    ];
    generic-vm = [
      # Extra keys only for the VM
    ];
  };

  allKeys = trustedKeys ++ (hostSpecificKeys.${config.networking.hostName} or []);
in
{
  options.eelco-authorized-keys = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = allKeys;
    description = "Authorized SSH keys for user Eelco based on trusted and host-specific keys.";
  };
}
