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

    # Ensure the correct environment for X11-based Plasma
    environment.sessionVariables = {
      XDG_SESSION_TYPE = "x11";
      QT_QPA_PLATFORM = "xcb";
    };
  };
}
