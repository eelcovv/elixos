{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.desktop.enableHyperland {
    programs.hyprland.enable = true;

    environment.systemPackages = with pkgs; [
      hyprpaper
      waybar
      rofi-wayland
      foot
      kitty
      dunst
      networkmanagerapplet
      wl-clipboard
      brightnessctl
      grim
      slurp
      swaynotificationcenter
      pavucontrol
      neofetch
      libnotify
      htop
    ];

    environment.sessionVariables = {
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
    };
  };
}
