{ pkgs, config, ... }: {
  xdg.mimeApps.enable = true;

  home.file.".local/share/mime/packages/drawio.xml" = {
    source = ./drawio-mimetype.xml;
    onChange = ''
      echo "Mime type for drawio added, home-manager will update the database."
    '';
    postUpdate = ''
      update-mime-database $HOME/.local/share/mime
    '';
  };

  xdg.mimeApps.defaultApplications = {
    "application/vnd.jgraph.mxfile" = [ "drawio.desktop" ];
    "application/x-drawio" = [ "drawio.desktop" ];

    # Web
    "text/html" = "firefox.desktop";
    "x-scheme-handler/http" = "firefox.desktop";
    "x-scheme-handler/https" = "firefox.desktop";
    "x-scheme-handler/about" = "firefox.desktop";
    "x-scheme-handler/unknown" = "firefox.desktop";

    # PDF
    "application/pdf" = "evince.desktop";

    # Text
    "text/plain" = "code.desktop";

    # Images
    "image/jpeg" = "geeqie.desktop";
    "image/png" = "geeqie.desktop";
    "image/gif" = "geeqie.desktop";
    "image/bmp" = "geeqie.desktop";
    "image/svg+xml" = "geeqie.desktop";

    # Video
    "video/mp4" = "vlc.desktop";
    "video/x-matroska" = "vlc.desktop";
    "video/webm" = "vlc.desktop";

    # Audio
    "audio/mpeg" = "vlc.desktop";
    "audio/ogg" = "vlc.desktop";
    "audio/wav" = "vlc.desktop";

    # Documents
    "application/vnd.oasis.opendocument.text" = "libreoffice-writer.desktop";
    "application/msword" = "libreoffice-writer.desktop";
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "libreoffice-writer.desktop";

    # Spreadsheets
    "application/vnd.oasis.opendocument.spreadsheet" = "libreoffice-calc.desktop";
    "application/vnd.ms-excel" = "libreoffice-calc.desktop";
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "libreoffice-calc.desktop";

    # Presentations
    "application/vnd.oasis.opendocument.presentation" = "libreoffice-impress.desktop";
    "application/vnd.ms-powerpoint" = "libreoffice-impress.desktop";
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "libreoffice-impress.desktop";
  };
}
