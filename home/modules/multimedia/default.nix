{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    mplayer
    kdePackages.gwenview
    geeqie
    thumbs
    cheese
    spotify
    kdePackages.kdenlive
    amarok
    ffmpeg
    sane-frontends
    sane-airscan
  ];
}
