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

    # PulseAudio is nodig voor audio over RDP
    hardware.pulseaudio.enable = true;
  };
}
