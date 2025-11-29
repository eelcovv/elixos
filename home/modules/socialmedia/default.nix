{pkgs, ...}: {
  home.packages = with pkgs; [
    telegram-desktop
    wasistlos
    signal-desktop
    nextcloud-client
    nextcloud-talk-desktop
  ];
}
