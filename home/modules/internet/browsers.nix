{pkgs, ...}: {
  home.packages = with pkgs; [
    firefox
    chromium
    epiphany
    google-chrome
    brave
    qutebrowser
    tor-browser
    protonmail-desktop
    transmission_4 # torrent client -browser
    protonmail-desktop
    biglybt # torrent client
    transmission_4 # torrent client
    qbittorrent
  ];
}
