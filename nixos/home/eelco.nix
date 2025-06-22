{ config, pkgs, lib, ... }:

{
  home-manager.users.eelco = {
    home.stateVersion = "24.11";

    imports = [
      ./modules/inputrc.nix
      ./modules/git.nix
      ./modules/zsh.nix
      ./modules/common-packages.nix
    ];
  };
}
