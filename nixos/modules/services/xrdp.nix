{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xrdp = {
      enable = true;

      #defaultWindowManager = "gnome-session --session=gnome-xorg";
      defaultWindowManager = "startplasma-x11";
    };

    security.pam.services.xrdp-sesman.enable = true;

    networking.firewall.allowedTCPPorts = [3389];
  };
}
