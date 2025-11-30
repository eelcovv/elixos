{ pkgs, config, ... }: {
  # 1. Zorg dat de algemene MIME support aanstaat (niet alleen de Apps)
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;

  # make sure you can find the icon
  home.file.".local/share/icons/hicolor/128x128/mimetypes/application-x-drawio.png" = {
    source = "${pkgs.drawio}/share/icons/hicolor/128x128/apps/drawio.png";
  };

  home.file.".local/share/mime/packages/drawio.xml" = {
    source = ./drawio-mimetype.xml;
    onChange = ''
      ${pkgs.shared-mime-info}/bin/update-mime-database $HOME/.local/share/mime
      # Update ook de icon cache voor de zekerheid
      ${pkgs.gtk3}/bin/gtk-update-icon-cache $HOME/.local/share/icons/hicolor || true
    '';
  };

  # Overwrite de desktop entry 
  xdg.desktopEntries.drawio = {
    name = "Draw.io";
    genericName = "Diagram Editor";
    exec = "${pkgs.drawio}/bin/drawio %U"; # <--- Hier zit de fix: %U
    terminal = false;
    categories = [ "Graphics" "Office" ];
    mimeType = [ "application/vnd.jgraph.mxfile" "application/x-drawio" ];
    # Zorg dat hij het juiste icoon pakt (verwijst naar die we eerder gefixt hebben of de standaard)
    icon = "drawio"; 
  };

  # 3. De associaties
  xdg.mimeApps.defaultApplications = {

    # Draw.io
    "application/vnd.jgraph.mxfile" = [ "drawio.desktop" ];
    "application/x-drawio" = [ "drawio.desktop" ];

    # Web
    "text/html" = [ "firefox.desktop" ];
    "x-scheme-handler/http" = [ "firefox.desktop" ];
    "x-scheme-handler/https" = [ "firefox.desktop" ];
    "x-scheme-handler/about" = [ "firefox.desktop" ];
    "x-scheme-handler/unknown" = [ "firefox.desktop" ];

    # PDF
    "application/pdf" = [ "org.gnome.Evince.desktop" ];

    # Text
    "text/plain" = [ "code.desktop" ];

    # Images
    "image/jpeg" = [ "gwenview.desktop" ];
    "image/png" = [ "gwenview.desktop" ];
    "image/gif" = [ "gwenview.desktop" ];
    "image/bmp" = [ "gwenview.desktop" ];
    "image/webp" = [ "gwenview.desktop" ];
    "image/svg+xml" = [ "gwenview.desktop" ];

    # Video
    "video/mp4" = [ "vlc.desktop" ];
    "video/x-matroska" = [ "vlc.desktop" ];
    "video/webm" = [ "vlc.desktop" ];

    # Audio
    "audio/mpeg" = [ "vlc.desktop" ];
    "audio/ogg" = [ "vlc.desktop" ];
    "audio/wav" = [ "vlc.desktop" ];

    # Documents (LibreOffice)
    "application/vnd.oasis.opendocument.text" = [ "writer.desktop" ];
    "application/msword" = [ "writer.desktop" ];
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [ "writer.desktop" ];

    # Spreadsheets
    "application/vnd.oasis.opendocument.spreadsheet" = [ "calc.desktop" ];
    "application/vnd.ms-excel" = [ "calc.desktop" ];
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [ "calc.desktop" ];

    # Presentations
    "application/vnd.oasis.opendocument.presentation" = [ "impress.desktop" ];
    "application/vnd.ms-powerpoint" = [ "impress.desktop" ];
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [ "impress.desktop" ];
  };
}
