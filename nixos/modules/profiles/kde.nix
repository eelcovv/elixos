{
  lib,
  pkgs,
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    # Activeer KWallet
    services.kwallet.enable = true;

    # Zorg dat PAM-integratie werkt
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
