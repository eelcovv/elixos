{ config, pkgs, lib, ... }:

{
  imports = [
    ./git-default.nix
    ./bash.nix
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
