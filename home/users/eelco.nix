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
      tls = {
        enable = true;
      };
    };

    smtp = {
      host = "mail.davelab.nl";
      port = 587;
      tls = {
        enable = true;
      };
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
      #../modules/databases
      #../modules/development
      ../modules/editors
      #../modules/engingeering
      #../modules/graphics
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
      (import ../modules/development/git.nix {
        inherit config pkgs lib;
        userName = "Eelco van Vliet";
        userEmail = "eelcovv@gmail.com";
      })
    ];

  home.sessionPath = ["$HOME/.local/bin"];

  dconf.settings = {
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
      ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Ghostty Console";
      command = "ghostty";
      binding = "<Super>t";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
      name = "Google Chrome";
      command = "google-chrome-stable";
      binding = "<Super>b";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
      name = "VSCode";
      command = "code";
      binding = "<Super>c";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
      name = "WasIstLos";
      command = "wasistlos";
      binding = "<Super><Shift>w";
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
      name = "KeeWeb";
      command = "keeweb";
      binding = "<Super>k";
    };
  };
}
