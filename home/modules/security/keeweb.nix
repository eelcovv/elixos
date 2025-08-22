{
  config,
  lib,
  pkgs,
  ...
}: let
  keewebBin = "${pkgs.keeweb}/bin/keeweb";
in {
  # Zorg dat het pakket aanwezig is (icons, resources)
  home.packages = [pkgs.keeweb];

  # Wrapper die de vlag altijd meegeeft
  home.file.".local/bin/keeweb" = {
    text = ''
      #!${pkgs.bash}/bin/bash
      exec ${keewebBin} --disable-gpu-sandbox "$@"
    '';
    executable = true;
  };

  # Overwrite the Desktop Launcher so that clicks also use the wrapper
  home.file.".local/share/applications/keeweb.desktop" = {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=KeeWeb
      GenericName=Password Manager
      Exec=keeweb %U
      Icon=keeweb
      Terminal=false
      Categories=Utility;Security;
      StartupWMClass=KeeWeb
      MimeType=application/x-keepass2;application/x-keepass2-kdbx;
      X-GNOME-UsesNotifications=true
    '';
  };
}
