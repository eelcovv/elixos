{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    nextcloud-client
  ];

  home.sessionVariables = {
    NEXTCLOUD_URL = "https://nx64056.your-storageshare.de/";
  };

  xdg.desktopEntries.nextcloud = {
    name = "Nextcloud";
    exec = "nextcloud";
    icon = "nextcloud";
    terminal = false;
    comment = "Access and synchronize files with Nextcloud";
    categories = ["Network" "FileTransfer"];
  };
}
