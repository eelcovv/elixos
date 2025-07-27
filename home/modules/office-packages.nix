{pkgs, ...}: {
  imports = [
    ./office/libreoffice.nix
    ./internet/browsers.nix
  ];
}
