{
  lib,
  pkgs,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.enableKde {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    environment.systemPackages = with pkgs.kdePackages; [
      kwallet
      kwallet-pam
      bluedevil
      plasma-workspace
      plasma-browser-integration
    ];

    security.pam.services.kwallet = {
      enable = true;
      kwallet = {
        enable = true;
      };
    };
  };
}
