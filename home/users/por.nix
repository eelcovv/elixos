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
      ../modules/common-packages.nix
      ../modules/hyperland
      ../modules/graphics-packages.nix
      ../modules/office-packages.nix
      ../modules/shells.nix
      ../modules/terminals.nix
      ../modules/editors.nix
      ../modules/internet/remote-access.nix

      # Uitpakken van benchmarking lijst:
    ]
    ++ [
      (import ../modules/shells/zsh.nix {
        inherit pkgs lib config;
      })
    ]
    ++ [
      (import ../modules/devel/git.nix {
        inherit config pkgs lib;
        userName = "Karnrawee Mangkang";
        userEmail = "karnrawee.mangkang@gmail.com";
      })
    ];

  # keyboard configuration for hyperland
  xdg.configFile."hypr/conf/keyboard-local.conf".text = ''
    input {
      kb_layout = us,th
      kb_options = grp:alt_shift_toggle
    }
  '';

  # Set up keyboard layout for gnome
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      sources = [(lib.gvariant.mkTuple ["xkb" "us"]) (lib.gvariant.mkTuple ["xkb" "th"])];
      xkb-options = ["grp:alt_shift_toggle"];
    };
  };

  home.sessionPath = ["$HOME/.local/bin"];
}
