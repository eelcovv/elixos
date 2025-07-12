{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [

    # GNOME instellingen
    (lib.mkIf config.desktop.enableGnome (
      (import ./gnome.nix { inherit lib pkgs; }).config
    ))

    # KDE instellingen
    (lib.mkIf config.desktop.enableKde (
      (import ./kde.nix { inherit lib pkgs; }).config
    ))

    # Hyperland instellingen
    (lib.mkIf config.desktop.enableHyperland (
      (import ./hyperland.nix { inherit lib pkgs; }).config
    ))

    # GDM alleen aanzetten als GNOME of KDE actief is
    (lib.mkIf (config.desktop.enableGnome || config.desktop.enableKde) {
      services.displayManager.gdm.enable = true;
      services.displayManager.gdm.autoLogin.enable = false;
      services.displayManager.gdm.autoLogin.user = lib.mkForce null;

      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })
  ];
}

