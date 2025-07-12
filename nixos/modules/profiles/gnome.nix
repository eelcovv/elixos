{ config, lib, ... }:

{
  config = lib.mkIf config.desktop.enableGnome {
    services.xserver.enable = true;
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;
    programs.ssh.askPassword = lib.mkForce "${config.pkgs.openssh}/libexec/ssh-askpass";
  };
}
