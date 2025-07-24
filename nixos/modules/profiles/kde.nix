{
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.kwallet
      kdePackages.kwallet-pam
    ];

    security.pam.services.kwallet = {
      enable = true;
      kwallet = {
        enable = true;
      };
      # Let op: GEEN kwallet5 hier
    };

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "KDE";
      XDG_SESSION_DESKTOP = "KDE";
    };
  };
}
