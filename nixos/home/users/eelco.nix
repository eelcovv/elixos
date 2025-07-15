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
    ../modules/hyperland
    ../modules/devel-packages.nix
    ../modules/maintainance-packages.nix
    ../modules/office-packages.nix

    #(import ../modules/office/thunderbird.nix {
    #  inherit pkgs;
    #  accounts = [
    #    "eelco@davelab.nl"
    #  ];
    #})

    (import ../modules/devel/git.nix {
      inherit config pkgs lib;
      userName = "Eelco van Vliet";
      userEmail = "eelcovv@gmail.com";
    })
  ];

  #programs.nextcloud-extra = {
  #  enable = true;
  #  url = "https://cloud.davelab.nl";
  #};
}
