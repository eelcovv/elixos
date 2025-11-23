{
  lib,
  pkgs,
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.gnome.enable = true;
    services.gnome.gnome-initial-setup.enable = false;
    security.rtkit.enable = true;

    environment.sessionVariables = {
      NO_AT_BRIDGE = "1";
      GTK_A11Y = "none";
    };

    systemd.user.services."at-spi-dbus-bus".enable = false;

    environment.systemPackages = with pkgs; [
      gtk3
      gdk-pixbuf
      gsettings-desktop-schemas
      librsvg
    ];
  };
}
