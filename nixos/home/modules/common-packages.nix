{ config, pkgs, lib, ... }:

{
  imports = [
    ./bash.nix
    ./git.nix
    ./inputrc.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    neovim
    htop
    wget
    tree
  ];
}

