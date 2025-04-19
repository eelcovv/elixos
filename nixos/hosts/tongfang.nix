{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/tongfang.nix
    ../users/eelco.nix
    ../users/testuser.nix
  ];

  networking.hostName = "tongfang";
  system.stateVersion = "24.05";
}
