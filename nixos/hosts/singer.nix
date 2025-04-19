{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/singer.nix
    ../users/por.nix
    ../users/eelco.nix
  ];

  networking.hostName = "singer";
  system.stateVersion = "24.05";
}
