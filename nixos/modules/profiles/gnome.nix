{
  lib,
  pkgs,
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.gnome.enable = true;

    environment.systemPackages = with pkgs.kdePackages; [
      gtk3
      gdk-pixbuf
      gsettings-desktop-schemas
      at-spi2-core
      librsvg
    ];
  };
}
