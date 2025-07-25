{pkgs, ...}: {
  home.packages = [
    pkgs.firefox
    pkgs.chromium
    pkgs.google-chrome
    pkgs.tor-browser
    pkgs.brave
  ];
}
