{pkgs, ...}: {
  home.packages = with pkgs; [
    dunst # Minimal X11-compatible notification daemon
    swaynotificationcenter # Notification center voor Wayland compositors
  ];
}
