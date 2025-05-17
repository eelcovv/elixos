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
    ../home/eelco.nix

    # Add modules
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
  ];

  swapDevices = [{
    device = "/swapfile";
    size = "8G";
  }];

  networking.hostName = "singer";

  desktop.enableGnome = true;
  desktop.enableKde = false;
  desktop.enableHyperland = false;

}