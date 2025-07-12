{ lib, pkgs }: {
  config = lib.mkIf true {
    services.xserver.enable = true;
    services.desktopManager.plasma6.enable = true;
    services.displayManager.gdm.enable = true;

    programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
  };
}
