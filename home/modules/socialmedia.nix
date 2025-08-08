{pkgs, ...}: {
  imports = [
    office/jitsi.nix
  ];
  home.packages = with pkgs; [
    telegram-desktop
    whatsapp-for-linux
    signal-desktop
    nextcloud-client
  ];
}
