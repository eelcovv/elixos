{ config, pkgs, lib, ... }:

{
  home.username = "por";
  home.homeDirectory = "/home/por";
  home.stateVersion = "24.05"; # Gebruik de juiste versie hier

  imports = [
    ./modules/common-packages.nix

    # Personal overrides
    (import ./modules/git.nix {
      inherit config pkgs lib;
      userName = "Por Mangkang";
      userEmail = "karnrawee.mangkang@gmail.com";
    })
  ];
}
