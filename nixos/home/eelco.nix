{ config, pkgs, lib, flake, ... }:

{
  home-manager.users.eelco = {
    home.stateVersion = "24.11";

    imports = [
      (import ./modules/git.nix {
        inherit pkgs flake;
      })
      ./modules/inputrc.nix
      ./modules/zsh.nix
      ./modules/common-packages.nix
    ];
  };
}
