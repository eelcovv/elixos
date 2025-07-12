{ config, lib, pkgs, ... }: {
  config = {
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
  };
}

