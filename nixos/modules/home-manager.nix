{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.eelco = import "${inputs.self}/nixos/home/users/eelco.nix";
  home-manager.users.por = import "${inputs.self}/nixos/home/users/por.nix";
}

