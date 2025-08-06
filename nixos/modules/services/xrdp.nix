{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xrdp = {
      enable = true;

      # Start KDE Plasma via X11 for RDP sessions
      defaultWindowManager = "startplasma-x11";
    };

    # Open the default RDP port (3389)
    networking.firewall.allowedTCPPorts = [3389];

    # Enable PAM support for systemd --user sessions (required by Plasma)
    security.pam.services.xrdp-sesman.enable = true;
  };
}
