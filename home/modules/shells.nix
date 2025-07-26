{
  config,
  pkgs,
  lib,
  ...
}: {
  # note that we import zsh via users
  imports = [
    ./shells/bash.nix
    ./shells/inputrc.nix
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
