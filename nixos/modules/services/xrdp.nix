{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    services.xrdp = {
      enable = true;
      defaultWindowManager = "gnome-session"; # of plasma
    };

    networking.firewall.allowedTCPPorts = [3389];

    hardware.pulseaudio.enable = lib.mkDefault true;
  };
}
