{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.programs.nextcloud-extra;
  wrappedNextcloudTalkDesktop = pkgs.writeShellScriptBin "nextcloud-talk-desktop" ''
    export LD_LIBRARY_PATH=${pkgs.libglvnd}/lib:$LD_LIBRARY_PATH
    exec ${pkgs.nextcloud-talk-desktop}/bin/nextcloud-talk-desktop "$@"
  '';
in {
  options.programs.nextcloud-extra = {
    enable = lib.mkEnableOption "Enable extra Nextcloud configuration";

    url = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional Nextcloud server URL (used in env var)";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nextcloud-client = {
      enable = true;
      package = pkgs.nextcloud-client;
      settings = {
        startInBackground = true;
        launchOnSystemStartup = true;
      };
    };

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

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf (cfg.url != "") {
        NEXTCLOUD_URL = cfg.url;
      })
    ];
  };
}
