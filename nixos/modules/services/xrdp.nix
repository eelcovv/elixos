{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xrdp = {
      enable = true;
      defaultWindowManager = "gnome-session";
    };

    networking.firewall.allowedTCPPorts = [3389];
  };
}
