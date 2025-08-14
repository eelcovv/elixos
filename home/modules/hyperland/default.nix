{
  config,
  pkgs,
  lib,
  ...
}: let
  hyprDir = ./.;
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";

  cfg = config.hyprland;
in {
  options.hyprland = {
    # Option to toggle whether the Waybar submodule is imported
    enableWaybar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Import the Waybar submodule located at ./waybar.";
    };
  };

  # Conditionally import Waybar submodule
  imports = lib.optional cfg.enableWaybar ./waybar;

  ################################
  # Packages for Hyprland and desktop tools
  ################################
  home.packages = with pkgs; [
    kitty
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    brightnessctl
    pavucontrol
    wl-clipboard
    cliphist
    # Wallpaper/theme tools (can be moved to a separate wallpaper module later)
    matugen
    wallust
    waypaper
  ];

  ################################
  # Session environment variables
  ################################
  home.sessionVariables = {
    WALLPAPER_DIR = wallpaperTargetDir;
    SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh"; # Keep literal for runtime expansion
    # ROFI_CONFIG is set in Waybar module if enabled
  };

  ################################
  # Hyprland configuration files
  ################################
  xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
  xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
  xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
  xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
  xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

  ################################
  # Shared helper functions
  ################################
  home.file.".config/hypr/scripts/helper-functions.sh" = {
    source = "${hyprDir}/scripts/helper-functions.sh";
    executable = true;
  };

  ################################
  # Hyprpaper defaults and Waypaper configuration
  ################################
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperTargetDir}/default.png
    wallpaper = ,${wallpaperTargetDir}/default.png
    splash = false
  '';
  xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";
  xdg.configFile."waypaper".source = "${hyprDir}/waypaper";

  ################################
  # Ensure ~/.local/bin is in PATH
  ################################
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}
