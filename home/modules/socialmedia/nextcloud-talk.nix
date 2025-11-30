{ pkgs, ... }:
let
  wrappedNextcloudTalkDesktop = pkgs.writeShellScriptBin "nextcloud-talk-desktop" ''
    export LD_LIBRARY_PATH=${pkgs.libglvnd}/lib:$LD_LIBRARY_PATH
    exec ${pkgs.nextcloud-talk-desktop}/bin/nextcloud-talk-desktop "$@"
  '';
in {
  home.packages = [
    wrappedNextcloudTalkDesktop
  ];

  xdg.desktopEntries.nextcloud-talk = {
    name = "Nextcloud Talk";
    exec = "nextcloud-talk-desktop";
    icon = "nextcloud";
    terminal = false;
    comment = "Chat and video calls with Nextcloud Talk";
    categories = [ "Network" "Chat" ];
  };
}