{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xrdp = {
      enable = true;

      # Forceer X11 sessie voor GNOME, anders crasht het
      defaultWindowManager = "gnome-session --session=gnome-xorg";
    };

    security.pam.services.xrdp-sesman.enable = true;

    networking.firewall.allowedTCPPorts = [3389];
  };
}
