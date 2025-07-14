{
  pkgs,
  config ? {url = "";},
  ...
}: {
  programs.nextcloud-client = {
    enable = true;
    package = pkgs.nextcloud-client;

    # Als je ooit sync-folders of url’s declaratief wilt meegeven:
    settings = {
      startInBackground = true;
      launchOnSystemStartup = true;
      syncFolders = []; # ← optioneel later
    };
  };

  # Optioneel: een melding als de url is opgegeven (niet verplicht)
  home.sessionVariables = lib.mkIf (config.url != "") {
    NEXTCLOUD_URL = config.url;
  };
}
