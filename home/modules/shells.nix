{
  config,
  pkgs,
  lib,
  ...
}: {
  # note that we import zsh via users
  imports = [
    ./shell/bash.nix
    ./shell/inputrc.nix
  ];

  home.packages = with pkgs; [
    alejandra
    neovim
    htop
    wget
    tree
    direnv
  ];
}
