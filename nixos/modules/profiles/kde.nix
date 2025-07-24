{
  lib,
  pkgs,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.enableKde {
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
    };
  };
}
