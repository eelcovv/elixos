{ config, lib, pkgs, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # all shared home manager packages
  imports = [
    ../modules/home/common-packages.nix
  ];

}
