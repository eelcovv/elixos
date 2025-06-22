{ config, pkgs, lib, ... }:

{
  home-manager.users.eelco = {
    home.stateVersion = "24.11";

    imports = [
      (import ./modules/git.nix {
        inherit config pkgs lib;
        userName = "Eelco van Vliet";
        userEmail = "eelcovv@gmail.com";
      })
      ./modules/inputrc.nix
      ./modules/zsh.nix
      ./modules/git.nix
      ./modules/common-packages.nix
    ];
  };
}
