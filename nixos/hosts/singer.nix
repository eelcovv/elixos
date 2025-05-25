{ inputs, ... }:

{
  imports = [
    ../modules/common.nix
    ../modules/profiles/desktop.nix
    ../modules/home-manager.nix
    ../modules/secrets/singer-eelco.nix
    ../modules/services/ssh-client-keys.nix
    ../hardware/singer.nix
    ../disks/singer.nix
    ../users/eelco.nix
    ../users/por.nix
    ../home/eelco.nix
    ../home/por.nix

    # Add modules
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "singer";

  desktop.enableGnome = true;
  desktop.enableKde = false;
  desktop.enableHyperland = false;

}