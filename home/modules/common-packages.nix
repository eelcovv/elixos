{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fonts.nix
    ./devel/git-default.nix
    ./shell/bash.nix
    ./shell/inputrc.nix
    ./shell/zsh.nix
  ];

  home.packages = with pkgs; [
    neovim
    htop
    wget
    tree
    nautilus
    keeweb
    gnome-keyring
  ];
}
