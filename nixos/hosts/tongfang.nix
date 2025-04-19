{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/tongfang.nix
    ../users/users.nix
  ];

  networking.hostName = "tongfang";
  system.stateVersion = "24.05";
}
