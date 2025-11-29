{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.programs.nextcloud-extra;
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
    home.packages = [
      pkgs.nextcloud-client
    ];

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf (cfg.url != "") {
        NEXTCLOUD_URL = cfg.url;
      })
    ];
  };
}
