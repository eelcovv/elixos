{
  lib,
  pkgs,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.enableKde {
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs.kdePackages; [
      plasma-desktop
      plasma-workspace
      konsole
      dolphin
      plasma-browser-integration
      kwallet
      kwallet-pam
      bluedevil
    ];

    security.pam.services.kwallet = {
      enable = true;
      kwallet = {
        enable = true;
      };
    };
  };
}
