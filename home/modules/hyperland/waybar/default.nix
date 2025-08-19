{
  config,
  pkgs,
  lib,
  ...
}: {
  # Waybar-specific packages/config only.
  # No wallpaper fetching here (centralized in wallpapers/fetcher.nix).
  home.packages = with pkgs; [
    # add your waybar addons if any (rofi-wayland, etc.)
  ];

  # Your Waybar files/JSON/CSS go here (omitted since you didn’t include them)
  # xdg.configFile."waybar/config".source = ./config;
  # xdg.configFile."waybar/style.css".source = ./style.css;
}
