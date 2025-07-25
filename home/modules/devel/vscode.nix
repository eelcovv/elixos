{pkgs, ...}: {
  home.packages = [pkgs.vscode];

  #xdg.configFile."Code/User/settings.json".source = ./vscode-settings.json;

  # eventueel ook:
  # xdg.mimeApps.defaultApplications."text/plain" = "code.desktop";
}
