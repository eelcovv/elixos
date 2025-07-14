{
  pkgs,
  lib,
  cfg ? {url = "";},
  ...
}: {
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
}
