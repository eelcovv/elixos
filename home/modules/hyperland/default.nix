{
  config,
  pkgs,
  lib,
  ...
}: let
  # Read HOME_THEME only from the environment to avoid recursion.
  # Fallback to "default" when not provided by the caller (e.g., scripts).
  envTheme = builtins.getEnv "HOME_THEME";
  selected =
    if envTheme != ""
    then envTheme
    else "default";

  # Split "ml4w/dark" -> themeName="ml4w", variantPath="ml4w/dark"
  parts = lib.splitString "/" selected;
  themeName =
    if parts == []
    then "default"
    else builtins.head parts;
  variantPath =
    if parts == []
    then "default"
    else selected;

  hyprDir = ./.;
  waybarDir = ./waybar;
  rofiRoot = ./rofi;

  # Rofi: choose folder by THEME name, fallback to default if missing
  rofiThemeCandidate = "${rofiRoot}/themes/${themeName}";
  rofiThemePath =
    if builtins.pathExists rofiThemeCandidate
    then rofiThemeCandidate
    else "${rofiRoot}/themes/default";

  # Waybar: config lives in THEME folder; style lives in VARIANT folder
  waybarConfigCandidate = "${waybarDir}/themes/${themeName}/config.jsonc";
  waybarVariantDir = "${waybarDir}/themes/${variantPath}";
  styleCustom = "${waybarVariantDir}/style-custom.css";
  styleCss = "${waybarVariantDir}/style.css";

  finalConfigPath =
    if builtins.pathExists waybarConfigCandidate
    then waybarConfigCandidate
    else "${waybarDir}/themes/default/config.jsonc";

  finalStylePath =
    if builtins.pathExists styleCustom
    then styleCustom
    else if builtins.pathExists styleCss
    then styleCss
    else "${waybarDir}/themes/default/style.css";

  # Wallpapers
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
in {
  # Session variables (do NOT read HOME_THEME from config.* here)
  home.sessionVariables = {
    HOME_THEME = selected;
    WALLPAPER_DIR = wallpaperTargetDir;
    SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh";
  };

  # Hyprland configs
  xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
  xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
  xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
  xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
  xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

  # Waybar: expose themes tree for the picker, and pin config/style from selected theme/variant
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";
  xdg.configFile."waybar/config.jsonc".source = finalConfigPath;
  xdg.configFile."waybar/style.css".source = finalStylePath;
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

  # Rofi theme by THEME name
  xdg.configFile."rofi/config.rasi".source = "${rofiThemePath}/config.rasi";
  xdg.configFile."rofi/colors.rasi".source = "${rofiThemePath}/colors.rasi";

  # Hyprpaper defaults (runtime can still override)
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperTargetDir}/default.png
    wallpaper = ,${wallpaperTargetDir}/default.png
    splash = false
  '';

  # Default wallpaper + waypaper
  xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";
  xdg.configFile."waypaper".source = "${hyprDir}/waypaper";

  # Append ~/.local/bin without referencing config.home.sessionPath
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
  home.file.".local/bin/waybar-switch-theme".text =
    builtins.readFile ./scripts/waybar-switch-theme.sh;
  home.file.".local/bin/waybar-switch-theme".executable = true;
  home.file.".local/bin/waybar-pick-theme".text =
    builtins.readFile ./scripts/waybar-pick-theme.sh;
  home.file.".local/bin/waybar-pick-theme".executable = true;

  # Packages
  home.packages = with pkgs; [
    kitty
    rofi-wayland
    hyprpaper
    hyprshot
    hyprlock
    hypridle
    wofi
    rofimoji
    waybar
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
}
