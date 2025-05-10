{ pkgs, ... }:

{
  home.packages = with pkgs; [
    neovim
    htop
    wget
    tree
  ];
}
