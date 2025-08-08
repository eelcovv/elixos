{pkgs, ...}: {
  home.packages = with pkgs; [
    wl-clipboard # Wayland clipboard tools (wl-copy, wl-paste)
    xclip # Fallback voor X11 apps
    cliphist # Clipboard history manager (werkt goed met Hyprland)
  ];
}
