{
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    # PAM-integratie voor KWallet
    security.pam.services.kwallet = {
      enable = true;
      kwallet = true;
      kwallet5 = true;
    };

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
    };
  };
}
