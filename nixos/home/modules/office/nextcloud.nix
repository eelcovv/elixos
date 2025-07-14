{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.programs.nextcloud-extra;
in {
  options.programs.nextcloud-extra = {
    enable = mkEnableOption "Extra Nextcloud configuration";
    url = mkOption {
      type = types.str;
      default = "";
      description = "Optional default URL for Nextcloud.";
    };
  };

  config = mkIf cfg.enable {
    programs.nextcloud-client = {
      enable = true;
      package = pkgs.nextcloud-client;

      settings = {
        startInBackground = true;
        launchOnSystemStartup = true;
        syncFolders = [];
      };
    };

    home.sessionVariables = mkIf (cfg.url != "") {
      NEXTCLOUD_URL = cfg.url;
    };
  };
}
