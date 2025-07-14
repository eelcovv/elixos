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
    ../modules/office/nextcloud.nix

    (import ../modules/office/thunderbird.nix {
      inherit pkgs;
      accounts = [
        "eelco@davelab.nl"
        "eelcovv@gmail.com"
      ];
    })

    (import ../modules/devel/git.nix {
      inherit config pkgs lib;
      userName = "Eelco van Vliet";
      userEmail = "eelcovv@gmail.com";
    })
  ];

  programs.nextcloud-extra = {
    enable = true;
    url = "https://cloud.davelab.nl";
  };
}
