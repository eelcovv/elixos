{ inputs, ... }:

{
  imports = [
      ../modules/common.nix
    ../modules/profiles/desktop.nix
    ../modules/home-manager.nix
    ../modules/services/laptop.nix
    ../modules/secrets/singer.nix
    ../hardware/singer.nix
    ../disks/singer.nix
    ../users/eelco.nix
    ../home/eelco.nix

    # Add modules
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "singer";

  desktop.enableGnome = true;
  desktop.enableKde = true;
  desktop.enableHyperland = true;

}
