{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fonts.nix
  ];

  # Voeg ~/.local/bin (en desgewenst ~/bin) toe aan PATH via HM
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
  ];

  home-manager.backupFileExtension = "bak";

  home.packages = with pkgs; [
    htop
    wget
    tree
    nautilus
    pyright
    texlab
    nil
    polkit_gnome
    p7zip
    rar
  ];
}
