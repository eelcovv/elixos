{
  config,
  pkgs,
  lib,
  ...
}: {
  # Basic user
  home.username = "eelco";
  home.homeDirectory = "/home/eelco";
  home.stateVersion = "24.05";

  # XDG (needed for desktop entries)
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
      ../../modules/databases
      ../../modules/development
      ../../modules/editors
      ../../modules/engineering
      ../../modules/graphics
      ../../modules/hyperland
      ../../modules/internet
      ../../modules/maintainance
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
      ./email.nix
      ./git.nix
      ./gnome-bindings.nix
      ./nextcloud.nix
      ./zsh.nix
      ./ptgui.nix
    ];
}
