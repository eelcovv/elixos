{
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "eelco";
  home.homeDirectory = "/home/eelco";
  home.stateVersion = "24.05";

  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };

  accounts.email.accounts.eelco = {
    primary = true;
    address = "eelco@davelab.nl";
    userName = "eelco@davelab.nl";
    realName = "Eelco van Vliet";
    flavor = "plain";

    imap = {
      host = "mail.davelab.nl";
      port = 993;
      tls.enable = true; # ← GEEN type
    };

    smtp = {
      host = "mail.davelab.nl";
      port = 587;
      tls.enable = true; # ← GEEN type
    };

    thunderbird.enable = true;
  };

  home.packages = with pkgs; [
    nextcloud-client
  ];

  home.sessionVariables = {
    NEXTCLOUD_URL = "https://nx64056.your-storageshare.de/";
  };

  xdg.desktopEntries.nextcloud = {
    name = "Nextcloud";
    exec = "nextcloud";
    icon = "nextcloud";
    terminal = false;
    comment = "Access and synchronize files with Nextcloud";
    categories = ["Network" "FileTransfer"];
  };

  xdg.enable = true;

  # pick your default choise of desktop here.
  home.file.".dmrc".text = ''
    [Desktop]
    Session=hyprland
  '';
  imports =
    [
      ../modules/common-packages.nix
      ../modules/datascience.nix
      ../modules/hyperland
      ../modules/devel-packages.nix
      ../modules/maintainance-packages.nix
      ../modules/graphics-packages.nix
      ../modules/office-packages.nix
      ../modules/shells.nix
      ../modules/terminals.nix
      ../modules/editors.nix
      ../modules/internet/remote-access.nix

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
