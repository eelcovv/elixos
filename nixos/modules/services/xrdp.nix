{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xrdp = {
      enable = true;
      #defaultWindowManager = "gnome-session";
      defaultWindowManager = "gnome-session --session=gnome-classic";
    };

    networking.firewall.allowedTCPPorts = [3389];
  };
}
