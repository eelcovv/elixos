{
  lib,
  pkgs,
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.gnome.enable = true;
    services.gnome.gnome-initial-setup.enable = false;
    security.rtkit.enable = true;

    environment.systemPackages = with pkgs; [
      gtk3
      gdk-pixbuf
      gsettings-desktop-schemas
      librsvg
    ];
  };
}
