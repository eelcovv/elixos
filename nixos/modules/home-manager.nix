{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.eelco = import ../../home/users/eelco.nix;
  home-manager.users.por = import ../../home/users/por.nix;
}

