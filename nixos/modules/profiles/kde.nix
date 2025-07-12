{ config, lib, ... }:

{
  config = lib.mkIf config.desktop.enableKde {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.gdm.enable = true;
    programs.ssh.askPassword = lib.mkForce "${config.pkgs.openssh}/libexec/ssh-askpass";
  };
}
