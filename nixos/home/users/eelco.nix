{ config, pkgs, lib, ... }:

{
  home.username = "eelco";
  home.homeDirectory = "/home/eelco";
  home.stateVersion = "24.05";

  imports = [
    ../modules/common-packages.nix

    # Personal git configuration with explicit parameters
    (import ../modules/git.nix {
      inherit config pkgs lib;
      userName = "Eelco van Vliet";
      userEmail = "eelcovv@gmail.com";
    })
  ];
}

