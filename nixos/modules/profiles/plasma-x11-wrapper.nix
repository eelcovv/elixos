{
  config,
  lib,
  pkgs,
  ...
}: let
  plasmaX11Wrapped = pkgs.writeShellScript "startplasma-x11-wrapped" ''
    export XDG_SESSION_TYPE=x11
    export QT_QPA_PLATFORM=xcb
    exec ${pkgs.kdePackages.plasma-workspace}/bin/startplasma-x11
  '';
in {
  config = lib.mkIf config.desktop.enableKde {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;

    services.xserver.displayManager.session = [
      {
        name = "plasma-x11";
        start = "exec ${plasmaX11Wrapped}";
        manage = "desktop";
      }
    ];
  };
}
