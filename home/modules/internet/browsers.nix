{pkgs, ...}: {
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
