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
      ../modules/common
      ../modules/databases
      ../modules/devel
      ../modules/editors
      ../modules/engingeering
      ../modules/graphics
      ../modules/hyperland
      ../modules/internet
      ../modules/maintainance
      ../modules/multimedia
      ../modules/office
      ../modules/publishing
      ../modules/shells
      ../modules/security
      ../modules/socialmedia
      ../modules/terminals

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
