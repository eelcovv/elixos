{pkgs, ...}: {
  home.packages = with pkgs; [
    brightnessctl
    cliphist
    dunst # notification daemon
    matugen
    nautilus
    pasystray
    pavucontrol
    polkit_gnome
    swaynotificationcenter # Wayland notification daemon (ook voor andere compositors)
    wallust
    waypaper
    wl-clipboard
    xclip
  ];
}
