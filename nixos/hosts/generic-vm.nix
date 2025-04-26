{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/services/generic-vm.nix
    ../hardware/generic-vm.nix
    ../disks/generic-vm.nix
    ../users/eelco.nix
  ];

  networking.hostName = "generic-vm";
  system.stateVersion = "24.11";
}
