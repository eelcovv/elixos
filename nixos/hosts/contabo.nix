{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/contabo.nix
    ../users/users.nix
  ];

  networking.hostName = "contabo";
  system.stateVersion = "24.05";
}
