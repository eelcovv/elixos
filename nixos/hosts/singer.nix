{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/home-manager.nix
    ../modules/services/laptop.nix
    ../hardware/singer.nix
    ../disks/singer.nix
    ../users/eelco.nix
    ../home/eelco.nix

    # Add modules
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "singer";

}
