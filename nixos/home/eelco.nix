{ config, pkgs, lib, ... }:

{
  home.username = "eelco";
  home.homeDirectory = "/home/eelco";
  home.stateVersion = "24.11";

  imports = [
    ./modules/git.nix
    ./modules/inputrc.nix
    ./modules/zsh.nix
    ./modules/common-packages.nix
  ];
}
