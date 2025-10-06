{
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "por";
  home.homeDirectory = "/home/por";
  home.stateVersion = "24.05";

  xdg.enable = true;

  # Default session
  home.file.".dmrc".text = ''
    [Desktop]
    Session=hyprland
  '';

  # Extent path with .local/bin
  home.sessionPath = lib.mkDefault ["$HOME/.local/bin"];

  home.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.glibc
  ];

  # Import all modules
  imports =
    [
      ../../modules/common
      ../../modules/editors
      ../../modules/graphics
      ../../modules/hyperland
      ../../modules/internet
      ../../modules/multimedia
      ../../modules/office
      ../../modules/publishing
      ../../modules/shells
      ../../modules/security
      ../../modules/socialmedia
      ../../modules/terminals
    ]
    ++ (import ../../modules/benchmarking {inherit lib;})
    # Local sub modules for this  user (email/nextcloud/gnome)
    ++ [
      ./git.nix
      ./gnome-bindings.nix
      ./keyboard.nix
      ./zsh.nix
    ];
}
