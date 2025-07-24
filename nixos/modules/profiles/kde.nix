{
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    # PAM integration for Kwallet
    security.pam.services.kwallet = {
      enable = true;
      kwallet.enable = true;
      kwallet5.enable = true;
    };

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
    };
  };
}
