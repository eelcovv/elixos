{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/singer.nix
    ../users/users.nix
  ];

  networking.hostName = "singer";
  system.stateVersion = "24.05";
}
