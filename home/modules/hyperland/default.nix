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
    # Toggle importing the Waybar submodule at ./waybar
    enableWaybar = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Import the Waybar submodule located at ./waybar.";
    };

    # Toggle importing the Waypaper (wallpaper tools) submodule at ./waypaper
    wallpaper.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Import the Waypaper (wallpaper tools) submodule located at ./waypaper.";
    };
  };

  # Conditionally import submodules that live under this Hyprland module
  imports =
    (lib.optional cfg.enableWaybar ./waybar)
    ++ (lib.optional cfg.wallpaper.enable ./waypaper);

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
    # Wallpaper/theme tools (can be moved to a dedicated wallpaper module; kept here for convenience)
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
    # ROFI_CONFIG is set inside the Waybar submodule (if enabled)
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
  # Shared helper functions (used by Waybar/Waypaper submodules)
  ################################
  home.file.".config/hypr/scripts/helper-functions.sh" = {
    source = "${hyprDir}/scripts/helper-functions.sh";
    executable = true;
  };

  ################################
  # Hyprpaper defaults (base wallpaper; Waypaper submodule manages extra tooling)
  ################################
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperTargetDir}/default.png
    wallpaper = ,${wallpaperTargetDir}/default.png
    splash = false
  '';

  # Provide a default wallpaper image
  xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";

  # NOTE: do not symlink the ./waypaper folder here; it is a submodule (imported above).
  # If you keep a separate Waypaper app config directory, point to that explicitly.

  ################################
  # Ensure ~/.local/bin is in PATH
  ################################
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}
