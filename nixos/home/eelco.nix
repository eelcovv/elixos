{ config, pkgs, lib, ... }:

{
  home-manager.users.eelco = {
    home.stateVersion = "24.11";

    imports = [
      ./modules/common-packages.nix

      # Personal overrides
      (import ./modules/git.nix {
        inherit config pkgs lib;
        userName = "Eelco van Vliet";
        userEmail = "eelcovv@gmail.com";
      })
    ];
  };
}

