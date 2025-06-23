{ config, pkgs, lib, ... }:

{
  home-manager.users.eelco = {
    home.stateVersion = "24.11";

    imports = [
      ./modules/inputrc.nix
      ./modules/zsh.nix
      ./modules/common-packages.nix

      (import ./modules/git.nix {
        inherit config pkgs lib;
        name  = "Eelco van Vliet";
        email = "eelcovv@gmail.com";
      })
    ];
  };
}
