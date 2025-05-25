{ config, pkgs, lib, ... }:

{
  home-manager.users.por = {
    home.stateVersion = "24.11";

    imports = [
      ./modules/zsh.nix
      ./modules/common-packages.nix
    ];
  };
}
