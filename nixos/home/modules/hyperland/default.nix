{
  config,
  pkgs,
  ...
}: let
  wallpaperPath = ./wallpapers/nixos.png;
in {
  # Create back up in case of a conflict
  home-manager.backupFileExtension = "backup";

  xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;
  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;
  xdg.configFile."waybar/config.jsonc".source = ./waybar.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar.css;

  # Zorg dat de wallpaper beschikbaar is
  home.file."Pictures/wallpapers/nixos.png".source = wallpaperPath;

  # Install extra packages
  home.packages = with pkgs; [
    kitty
    rofi-wayland
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    waybar
    swaynotificationcenter
    dunst
    brightnessctl
    pavucontrol
    wl-clipboard
  ];
}
