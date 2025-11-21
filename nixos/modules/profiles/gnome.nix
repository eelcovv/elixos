{
  lib,
  pkgs,
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.gnome.enable = true;
    accessibility.enable = false;

    environment.systemPackages = with pkgs; [
      gtk3
      gdk-pixbuf
      gsettings-desktop-schemas
      librsvg
    ];
  };
}
