{
  config,
  pkgs,
  lib,
  ...
}: let
  hyprDir = ./.;
in {
  # Geen waypaper import meer:
  imports = [./waybar];

  home.packages = with pkgs; [
    hyprpaper
    hypridle
    hyprlock
    hyprshot
    wofi
    wl-clipboard
    cliphist
    brightnessctl
    pavucontrol
    kitty
  ];

  # Hyprland configs
  xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
  xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
  xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
  xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
  xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

  # Hyprpaper: altijd 1 pad
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    ipc = on
    splash = false
    preload = ~/.config/wallpapers/current.jpg
    wallpaper = ,~/.config/wallpapers/current.jpg
  '';

  # Seed wallpapers (base + current)
  home.activation.seedWallpapers = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    mkdir -p "$HOME/.config/wallpapers"
    # Kies zelf je basisplaat:
    if [ ! -e "$HOME/.config/wallpapers/base.jpg" ]; then
      cp -f "${hyprDir}/wallpapers/nixos.png" "$HOME/.config/wallpapers/base.jpg" || true
    fi
    if [ ! -e "$HOME/.config/wallpapers/current.jpg" ]; then
      ln -sfn "$HOME/.config/wallpapers/base.jpg" "$HOME/.config/wallpapers/current.jpg"
    fi
  '';

  # Handige tools in PATH
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}
