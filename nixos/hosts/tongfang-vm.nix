{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/services/tongfang-vm.nix
    ../hardware/tongfang-vm.nix
    ../disks/qemu-vm.nix
    ../users/eelco.nix
  ];

  networking.hostName = "tongfang-vm";
  system.stateVersion = "24.11";
}
