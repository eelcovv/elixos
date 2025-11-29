{ pkgs, ... }:
let
  wrappedNextcloudTalkDesktop = pkgs.writeShellScriptBin "nextcloud-talk-desktop" ''
    export LD_LIBRARY_PATH=${pkgs.libglvnd}/lib:$LD_LIBRARY_PATH
    exec ${pkgs.nextcloud-talk-desktop}/bin/nextcloud-talk-desktop "$@"
  '';
in {
  home.packages = [
    pkgs.nextcloud-client
    wrappedNextcloudTalkDesktop
  ];
}