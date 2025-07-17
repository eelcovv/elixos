{
  config,
  pkgs,
  ...
}: let
  wallpaperPath = ./wallpapers/nixos.png;
in {
  xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
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
    wofi
    waybar
    swaynotificationcenter
    dunst
    brightnessctl
    pavucontrol
    wl-clipboard
  ];
}
