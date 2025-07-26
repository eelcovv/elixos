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
    htop
    wget
    tree
    nautilus
    keeweb
    gnome-keyring
    pyright
    texlab
    nil
  ];
}
