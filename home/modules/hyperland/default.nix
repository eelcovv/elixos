{
  config,
  pkgs,
  lib,
  ...
}: let
  # Read HOME_THEME from the environment at evaluation time; fallback to "default"
  envTheme = builtins.getEnv "HOME_THEME";
  selected =
    if envTheme != ""
    then envTheme
    else (config.home.sessionVariables.HOME_THEME or "default");

  # Split "ml4w/dark" -> ["ml4w","dark"]; themeName is first segment, variantPath is the full string
  parts = lib.splitString "/" selected;
  themeName =
    if parts == []
    then "default"
    else builtins.head parts;
  variantPath =
    if parts == []
    then "default"
    else selected;

  # Layout roots inside this module
  hyprDir = ./.;
  waybarDir = ./waybar;
  rofiRoot = ./rofi;

  # Rofi theme folder: prefer themes/<themeName>, fallback to themes/default
  rofiThemeCandidate = "${rofiRoot}/themes/${themeName}";
  rofiThemePath =
    if builtins.pathExists rofiThemeCandidate
    then rofiThemeCandidate
    else "${rofiRoot}/themes/default";

  # Waybar: config comes from THEME folder; style from VARIANT folder
  waybarConfigPath = "${waybarDir}/themes/${themeName}/config.jsonc";
  waybarVariantDir = "${waybarDir}/themes/${variantPath}";
  styleCustomExists = builtins.pathExists (waybarVariantDir + "/style-custom.css");
  waybarStylePath =
    if styleCustomExists
    then "${waybarVariantDir}/style-custom.css"
    else "${waybarVariantDir}/style.css";

  # Wallpapers
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
in {
  # Expose variables to the session for scripts and tools
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

  # Waybar: make the whole themes tree available, then pin config/style from HOME_THEME
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";
  xdg.configFile."waybar/config.jsonc".source = waybarConfigPath;
  xdg.configFile."waybar/style.css".source = waybarStylePath;
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

  # Rofi: choose by THEME name (variant-independent), fallback to default
  xdg.configFile."rofi/config.rasi".source = "${rofiThemePath}/config.rasi";
  xdg.configFile."rofi/colors.rasi".source = "${rofiThemePath}/colors.rasi";

  # Hyprpaper defaults (runtime can still override)
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperTargetDir}/default.png
    wallpaper = ,${wallpaperTargetDir}/default.png
    splash = false
  '';

  # Ship a default wallpaper and waypaper config
  xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";
  xdg.configFile."waypaper".source = "${hyprDir}/waypaper";

  # Install helper scripts into ~/.local/bin (ensure it is on PATH)
  home.sessionPath = lib.unique ((config.home.sessionPath or []) ++ ["$HOME/.local/bin"]);

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
