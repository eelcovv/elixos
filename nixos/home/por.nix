{ config, pkgs, lib, ... }:

{
  home-manager.users.eelco = {
    home.stateVersion = "24.11";

    imports = [
      ./modules/common-packages.nix

      # Eventueel persoonlijke overrides
      (import ./modules/git.nix {
        inherit config pkgs lib;
        userName = "Por Mangkang";
        userEmail = "karnrawee.mangkang@gmail.com";
      })
    ];
  };
}
