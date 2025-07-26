{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fonts.nix
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
