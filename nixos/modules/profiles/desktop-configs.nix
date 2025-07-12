{ config, lib, pkgs, ... }:

{
  config = lib.mkMerge [

    # GNOME
    (lib.mkIf config.desktop.enableGnome {
      services.xserver.enable = true;
      services.desktopManager.gnome.enable = true;
      services.displayManager.gdm.enable = true;
      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })

    # KDE
    (lib.mkIf config.desktop.enableKde {
      services.xserver.enable = true;
      services.desktopManager.plasma6.enable = true;
      services.displayManager.gdm.enable = true;
      programs.ssh.askPassword = lib.mkForce "${pkgs.openssh}/libexec/ssh-askpass";
    })

    # Hyperland
    (lib.mkIf config.desktop.enableHyperland {
      programs.hyprland.enable = true;

      environment.systemPackages = with pkgs; [
        hyprpaper
        waybar
        foot
        kitty
        rofi-wayland
        dunst
        networkmanagerapplet
        wl-clipboard
        brightnessctl
        grim
        slurp
        pavucontrol
      ];
    })
  ];
}
