{
  config,
  pkgs,
  lib,
  ...
}: {
  home.username = "eelco";
  home.homeDirectory = "/home/eelco";
  home.stateVersion = "24.05";

  imports = [
    ../modules/common-packages.nix
    ../modules/devel-packages.nix
    ../modules/maintainance-packages.nix
    ../modules/office-packages.nix

    # Personal git configuration with explicit parameters
    (import ../modules/devel/git.nix {
      inherit config pkgs lib;
      userName = "Eelco van Vliet";
      userEmail = "eelcovv@gmail.com";
    })

    # Thunderbird config with user-specific accounts
    (import ../modules/office/thunderbird.nix {
      inherit pkgs;
      accounts = [
        "eelco@davelab.nl"
        "eelcovv@gmail.com"
      ];
    })

    # Nextcloud configuration
    (import ../modules/office/nextcloud.nix {
      inherit pkgs;
      config = {
        url = "https://cloud.davelab.nl";
      };
    })
  ];
}
