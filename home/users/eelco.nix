{
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "eelco";
  home.homeDirectory = "/home/eelco";
  home.stateVersion = "24.05";

  # pick your default choise of desktop here.
  home.file.".dmrc".text = ''
    [Desktop]
    Session=hyprland
  '';
  imports =
    [
      ../modules/common-packages.nix
      ../modules/hyperland
      ../modules/devel-packages.nix
      ../modules/maintainance-packages.nix
      ../modules/graphics-packages.nix
      ../modules/office-packages.nix
      ../modules/shells.nix
      ../modules/terminals.nix
      ../modules/editors.nix

      # Uitpakken van benchmarking lijst:
    ]
    ++ (import ../modules/benchmarking {inherit lib;})
    ++ [
      (import ../modules/shells/zsh.nix {
        inherit pkgs lib config;
      })
    ]
    ++ [
      (import ../modules/devel/git.nix {
        inherit config pkgs lib;
        userName = "Eelco van Vliet";
        userEmail = "eelcovv@gmail.com";
      })
    ];

  home.sessionPath = ["$HOME/.local/bin"];
}
