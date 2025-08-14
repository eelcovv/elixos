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
    pyright
    texlab
    nil
    polkit_gnome
    p7zip-rar
  ];
}
