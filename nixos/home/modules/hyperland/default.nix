{
  config,
  lib,
  pkgs,
  ...
}: {
  xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
  xdg.configFile."hypr/hyprpaper.conf".source = ./hyprpaper.conf;

  # Eventueel andere tools:
  xdg.configFile."waybar/config.jsonc".source = ./waybar/config.jsonc;
  xdg.configFile."rofi/config.rasi".source = ./rofi/config.rasi;
}
