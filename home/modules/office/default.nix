{pkgs, ...}: {
  imports = [
    ./libreoffice.nix
    ./jitsi.nix
    ./thunderbird.nix
  ];
  home.packages = with pkgs; [
    zoom-us
  ];
}
