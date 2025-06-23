{ config, pkgs, lib, ... }:

{
  home.username = "eelco";
  home.homeDirectory = "/home/eelco";
  home.stateVersion = "24.11";

  imports = [
    (import ./modules/git.nix {
      inherit config pkgs lib;
      userName = "Eelco van Vliet";
      userEmail = "eelcovv@gmail.com";
    })
    ./modules/inputrc.nix
    ./modules/zsh.nix
    ./modules/common-packages.nix
  ];
}
