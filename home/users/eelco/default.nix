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
  home.sessionPath = ["$HOME/.local/bin"];

  # Import all modules
  imports =
    [
      ../../modules/common
      ../../modules/databases
      ../../modules/development
      ../../modules/editors
      ../../modules/engingeering
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
      (import ../../modules/shells/zsh.nix {inherit pkgs lib config;})
      ./email.nix
      ./git.nix
      ./nextcloud.nix
      ./gnome-bindings.nix
    ];
}
