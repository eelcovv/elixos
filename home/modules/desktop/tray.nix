{pkgs, ...}: {
  home.packages = with pkgs; [
    pavucontrol # Volume control GUI (PulseAudio en PipeWire compatibel)
    pasystray # System tray volume icon (werkt met system tray)
    brightnessctl # CLI brightness controller (werkt in tray scripts)
  ];
}
