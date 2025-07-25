{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.programs.nextcloud-extra;
in {
  options.programs.nextcloud-extra = {
    enable = lib.mkEnableOption "Extra Nextcloud configuration";
    url = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional Nextcloud URL";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.nextcloud-client = {
      enable = true;
      package = pkgs.nextcloud-client;
      settings = {
        startInBackground = true;
        launchOnSystemStartup = true;
        syncFolders = [];
      };
    };

    home.sessionVariables = lib.mkIf (cfg.url != "") {
      NEXTCLOUD_URL = cfg.url;
    };
  };
}
