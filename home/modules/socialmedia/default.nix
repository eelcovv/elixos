{pkgs, ...}: {
  home.packages = with pkgs; [
    telegram-desktop
    whatsapp-for-linux
    signal-desktop
    nextcloud-client
    nextcloud-talk-desktop
  ];
}
