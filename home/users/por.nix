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
      ../modules/common
      ../modules/hyperland
      ../modules/graphics
      ../modules/office
      ../modules/internet
      ../modules/shells
      ../modules/terminals
      ../modules/editors

      # Uitpakken van benchmarking lijst:
    ]
    ++ [
      (import ../modules/shells/zsh.nix {
        inherit pkgs lib config;
      })
    ]
    ++ [
      (import ../modules/development/git.nix {
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
