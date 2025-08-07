{
  lib,
  pkgs,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.enableKde {
    services.xserver = {
      enable = true;
      displayManager = {
        gdm.enable = true;
        gdm.wayland = lib.mkForce false;
        sessionPackages = with pkgs; [
          (pkgs.writeTextDir "share/xsessions/plasma-x11.desktop" ''
            [Desktop Entry]
            Version=1.0
            Type=XSession
            Exec=${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11
            TryExec=${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11
            Name=KDE Plasma (X11)
            DesktopNames=KDE
          '')
        ];
      };
      desktopManager.plasma6.enable = true;
    };
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
