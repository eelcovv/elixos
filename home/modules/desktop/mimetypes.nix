{
  xdg.mimeApps.enable = true;

  home.file.".local/share/mime/packages/drawio.xml" = {
    source = ./drawio-mimetype.xml;
    # Let home-manager's xdg.mime module handle database updates
    onChange = ''
      echo "Mime type for drawio added, home-manager will update the database."
    '';
  };

  xdg.mimeApps.defaultApplications = {
    "application/vnd.jgraph.mxfile" = [ "drawio.desktop" ];
    "application/x-drawio" = [ "drawio.desktop" ];
  };
}
