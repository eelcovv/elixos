{
  config,
  pkgs,
  lib,
  ...
}: let
  # Keep paths to your module assets
  hyprDir = ./.;
  waybarDir = ./waybar;
  rofiRoot = ./rofi;

  # Rofi theme: keep static "default" (pure setup; no env-based switching here)
  rofiThemePath =
    if builtins.pathExists "${rofiRoot}/themes/default"
    then "${rofiRoot}/themes/default"
    else rofiRoot;

  # Wallpapers
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
in {
  ############################
  # Packages (Waybar provided by programs.waybar)
  ############################
  home.packages = with pkgs; [
    kitty
    rofi-wayland
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    rofimoji
    swaynotificationcenter
    dunst
    brightnessctl
    pavucontrol
    wl-clipboard
    cliphist
    matugen
    wallust
    waypaper
  ];

  ############################
  # Session environment
  ############################
  # Note: keep SSH_AUTH_SOCK with a literal $XDG_RUNTIME_DIR to be expanded at runtime.
  home.sessionVariables = {
    WALLPAPER_DIR = wallpaperTargetDir;
    SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh";
  };

  ############################
  # Hyprland configs
  ############################
  xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
  xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
  xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
  xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
  xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

  ############################
  # Waybar (pure: variant selected at runtime via ~/.config/waybar/current)
  ############################
  # Install the complete themes tree (read-only symlink to the Nix store)
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";

  # Stable top-level config delegates to the active variant via "current/"
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      // Main config delegates to the currently selected variant
      "include": [
        "~/.config/waybar/current/config.jsonc",
        "~/.config/waybar/current/modules.jsonc"
      ]
    }
  '';

  # Stable stylesheet that imports from the active variant
  xdg.configFile."waybar/style.css".text = ''
    /* Delegate styling to the current variant */
    @import url("current/style.css");
    /* Optional: if variants ship a palette */
    @import url("current/colors.css");
  '';

  # Create/refresh ~/.config/waybar/current (outside read-only themes/)
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CFG="$HOME/.config/waybar"
    mkdir -p "$CFG"
    DEFAULT="$CFG/themes/default"   # change if you want a different initial variant
    TARGET="$CFG/current"
    if [ ! -e "$TARGET" ]; then
      ln -sfn "$DEFAULT" "$TARGET"
    fi
  '';

  # Waybar via systemd user service (do NOT autostart via Hyprland exec-once)
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;

  ############################
  # Rofi (static default; pure)
  ############################
  xdg.configFile."rofi/config.rasi".source = "${rofiThemePath}/config.rasi";
  xdg.configFile."rofi/colors.rasi".source = "${rofiThemePath}/colors.rasi";

  ############################
  # Hyprpaper defaults
  ############################
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperTargetDir}/default.png
    wallpaper = ,${wallpaperTargetDir}/default.png
    splash = false
  '';

  # Default wallpaper + waypaper config
  xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";
  xdg.configFile."waypaper".source = "${hyprDir}/waypaper";

  ############################
  # Scripts & helper installation
  ############################
  # Add ~/.local/bin to PATH
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

  # Install helper under ~/.local/lib/waybar-theme/
  home.file.".local/lib/waybar-theme/helper-functions.sh".text =
    builtins.readFile ./scripts/helper-functions.sh;
  home.file.".local/lib/waybar-theme/helper-functions.sh".executable = true;

  # Install switch/pick scripts under ~/.local/bin/
  home.file.".local/bin/waybar-switch-theme".text =
    builtins.readFile ./scripts/waybar-switch-theme.sh;
  home.file.".local/bin/waybar-switch-theme".executable = true;

  home.file.".local/bin/waybar-pick-theme".text =
    builtins.readFile ./scripts/waybar-pick-theme.sh;
  home.file.".local/bin/waybar-pick-theme".executable = true;
}
