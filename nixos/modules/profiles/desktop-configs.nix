{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [
    (lib.mkIf config.desktop.enableGnome (
      (import ./gnome.nix { inherit lib pkgs; }).config // {
        services.displayManager.gdm.enable = true;
        programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
      }
    ))

    (lib.mkIf config.desktop.enableKde (
      (import ./kde.nix { inherit lib pkgs; }).config // {
        services.displayManager.gdm.enable = true;
        programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
      }
    ))

    (lib.mkIf config.desktop.enableHyperland (
      (import ./hyperland.nix { inherit lib pkgs; }).config
    ))
  ];
}

