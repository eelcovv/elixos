{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../hardware/tongfang-vm.nix
    ../users/eelco.nix
  ];

  networking.hostName = "tongfang-vm";
  system.stateVersion = "24.11";
}
