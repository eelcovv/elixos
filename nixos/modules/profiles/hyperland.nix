{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.desktop.enableHyperland {
    programs.hyprland.enable = true;

    services.blueman.enable = true;

    environment.systemPackages = with pkgs; [
      hyprpaper
      waybar
      networkmanagerapplet
      brightnessctl
      grim
      slurp
      neofetch
      libnotify
      blueman
    ];
  };
}
