{
  config,
  pkgs,
  lib,
  ...
}: let
  # Read HOME_THEME only from the environment to avoid recursion during evaluation.
  # Fallback to "default" when not provided (e.g., when called by Home Manager).
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

  # Rofi: choose the folder by THEME name; fallback to default if missing
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
  # Packages (Waybar is provided by programs.waybar; keep others here)
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

  # Session variables
  # Note: SSH_AUTH_SOCK keeps a literal $XDG_RUNTIME_DIR to be interpreted at runtime.
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
  # Install the whole themes tree (read-only symlink to the store)
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";

  # Stable config that includes the active variant via ~/.config/waybar/current
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "include": [
        "~/.config/waybar/current/config.jsonc",
        "~/.config/waybar/current/modules.jsonc"
      ]
    }
  '';

  # Stable stylesheet that imports from the active variant
  xdg.configFile."waybar/style.css".text = ''
    @import url("current/style.css");
    @import url("current/colors.css");
  '';

  # Create/refresh ~/.config/waybar/current (not inside read-only themes/)
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CFG="$HOME/.config/waybar"
    mkdir -p "$CFG"
    # Point to default variant on first install; adjust if you want a different initial target
    DEFAULT="$CFG/themes/default"
    TARGET="$CFG/current"
    if [ ! -e "$TARGET" ]; then
      ln -sfn "$DEFAULT" "$TARGET"
    fi
  '';

  # Waybar via systemd user service
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;
}
