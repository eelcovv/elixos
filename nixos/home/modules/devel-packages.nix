{ config, pkgs, lib, ... }:

{
  imports = [
    ./devel/git-default.nix
    ./devel/vscode.nix
    ./shell/bash.nix
    ./shell/inputrc.nix
    ./shell/zsh.nix
  ];

  home.packages = with pkgs; [
    neovim
    htop
    wget
    tree
    direnv
  ];
}
