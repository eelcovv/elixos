{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.desktop.enableHyperland {
    programs.hyprland.enable = true;

    # Hyprland werkt met Wayland direct, dus geen xserver of gdm nodig.
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
  };
}

