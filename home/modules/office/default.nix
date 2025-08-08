{pkgs, ...}: {
  imports = [
    ./libreoffice.nix
    ./jitsi.nix
    ./thunderbird.nix
  ];
}
