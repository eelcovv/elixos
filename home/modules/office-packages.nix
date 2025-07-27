{pkgs, ...}: {
  imports = [
    ./office/libreoffice.nix
    ./office/nextcloud.nix
    ./office/thunderbird.nix
    ./internet/browsers.nix
  ];
}
