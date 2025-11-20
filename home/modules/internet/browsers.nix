{ pkgs, ... }:

{
  home.packages = with pkgs; [
    #
    # Browsers
    #
    brave
    chromium
    epiphany
    firefox
    google-chrome
    librewolf
    mullvad-browser
    opera
    qutebrowser
    tor-browser
    vivaldi

    #
    # Bittorrent
    #
    qbittorrent
    transmission_4

    #
    # Mail
    #
    protonmail-desktop
  ];
}