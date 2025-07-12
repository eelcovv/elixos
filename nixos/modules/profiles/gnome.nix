{ config, lib, pkgs, ... }: {
  config = {
    services.xserver.enable = true;
    services.desktopManager.gnome.enable = true;
    services.displayManager.gdm.enable = true;
    programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
  };
}

