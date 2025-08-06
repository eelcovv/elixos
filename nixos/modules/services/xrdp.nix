{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xrdp = {
      enable = true;
      defaultWindowManager = "gnome-session --session=gnome-classic";
    };

    security.pam.services.xrdp-sesman.enable = true;

    networking.firewall.allowedTCPPorts = [3389];
  };
}
