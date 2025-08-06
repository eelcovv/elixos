{
  config,
  lib,
  pkgs,
  ...
}: {
  services.gnome.gnome-remote-desktop = {
    enable = true;
    # RDP vereist een wachtwoord, stel dit apart in
  };

  # Activeer de gnome keyring en portal services
  services.gnome.gnome-keyring.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gnome];

  # RDP gebruikt PipeWire om het scherm te delen
  security.pam.services.gdm.enableGnomeKeyring = true;

  # Firewall openzetten voor RDP (poort 3389)
  networking.firewall.allowedTCPPorts = [3389];
}
