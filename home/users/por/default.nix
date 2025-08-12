{
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "por";
  home.homeDirectory = "/home/por";
  home.stateVersion = "24.05";

  imports =
    [
      ../../modules/common
      ../../modules/hyperland
      ../../modules/graphics
      ../../modules/office
      ../../modules/internet
      ../../modules/shells
      ../../modules/terminals
      ../../modules/editors
    ]
    # Lokale user-specifieke modules
    ++ [
      ./git.nix
      ./keyboard.nix
      ./zsh.nix
    ];

  home.sessionPath = ["$HOME/.local/bin"];
}
