{
  config,
  lib,
  pkgs,
  ...
}: {
  services.xrdp = {
    enable = true;
    defaultWindowManager = "gnome-session"; # of "startplasma-x11" voor KDE
  };

  # Open poort voor RDP
  networking.firewall.allowedTCPPorts = [3389];

  # Extra (optioneel): als PulseAudio nodig is voor geluid
  hardware.pulseaudio.enable = lib.mkDefault true;
}
