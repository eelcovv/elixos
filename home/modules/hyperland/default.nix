{
  config,
  pkgs,
  lib,
  ...
}: let
  # Paths to assets in this module
  hyprDir = ./.;
  waybarDir = ./waybar;
  rofiRoot = ./rofi;

  # Rofi theme (static default; keep pure)
  rofiThemePath =
    if builtins.pathExists "${rofiRoot}/themes/default"
    then "${rofiRoot}/themes/default"
    else rofiRoot;

  # Wallpapers
  wallpaperDir = ./wallpapers;
  wallpaperTargetDir = "${config.xdg.configHome}/wallpapers";
in {
  ################################
  # Packages (Waybar via programs.waybar)
  ################################
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

  ################################
  # Session environment
  ################################
  home.sessionVariables = {
    WALLPAPER_DIR = wallpaperTargetDir;
    # Keep literal $XDG_RUNTIME_DIR for runtime expansion
    SSH_AUTH_SOCK = "${"$XDG_RUNTIME_DIR"}/keyring/ssh";
  };

  ################################
  # Hyprland configs
  ################################
  xdg.configFile."hypr/hyprland.conf".source = "${hyprDir}/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = "${hyprDir}/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = "${hyprDir}/hypridle.conf";
  xdg.configFile."hypr/colors.conf".source = "${hyprDir}/colors.conf";
  xdg.configFile."hypr/conf".source = "${hyprDir}/conf";
  xdg.configFile."hypr/effects".source = "${hyprDir}/effects";
  xdg.configFile."hypr/scripts".source = "${hyprDir}/scripts";

  ################################
  # Waybar (pure: select variant at runtime via ~/.config/waybar/current/)
  ################################
  # Read-only themes tree from the Nix store
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";

  # Global fallbacks (used if a theme/variant lacks these files)
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

  # Top-level config includes the *resolved* files in current/
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "include": [
        "~/.config/waybar/current/config.jsonc",
        "~/.config/waybar/current/modules.jsonc"
      ]
    }
  '';

  # IMPORTANT: always import the preprocessed CSS produced in ~/.config/waybar/current/
  xdg.configFile."waybar/style.css".text = ''
    @import url("current/style.resolved.css");
  '';

  # Ensure ~/.config/waybar/current/ is a directory (not a symlink) and seed safe defaults.
  # We also create a valid style.resolved.css that never references ~/colors.css,
  # so Waybar cannot crash during rebuilds.
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CFG="$HOME/.config/waybar"
    BASE="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG"
    # Replace any legacy symlink with a real directory
    [ -L "$CUR" ] && rm -f "$CUR"
    mkdir -p "$CUR"

    # Pick default sources (best effort)
    DEF="$BASE/default"
    MOD_GLOBAL="$CFG/modules.jsonc"
    COL_GLOBAL="$CFG/colors.css"

    CFG_SRC="$DEF/config.jsonc"
    [ -e "$CFG_SRC" ] && ln -sfn "$CFG_SRC" "$CUR/config.jsonc"

    MOD_SRC="$DEF/modules.jsonc"
    [ -e "$MOD_SRC" ] || MOD_SRC="$MOD_GLOBAL"
    [ -n "$MOD_SRC" ] && [ -e "$MOD_SRC" ] && ln -sfn "$MOD_SRC" "$CUR/modules.jsonc"

    COL_SRC="$DEF/colors.css"
    [ -e "$COL_SRC" ] || COL_SRC="$COL_GLOBAL"
    if [ -n "$COL_SRC" ] && [ -e "$COL_SRC" ]; then
        ln -sfn "$COL_SRC" "$CUR/colors.css"
    else
        : > "$CUR/colors.css"
    fi

    CSS_SRC=""
    if [ -e "$DEF/style.css" ]; then
        CSS_SRC="$DEF/style.css"
    elif [ -e "$DEF/style-custom.css" ]; then
        CSS_SRC="$DEF/style-custom.css"
    fi

    if [ -n "$CSS_SRC" ]; then
        # Build a resolved CSS:
        #   1) copy the chosen CSS,
        #   2) replace literal ~/colors.css -> colors.css,
        #   3) always prepend an import for colors.css
        cp -f "$CSS_SRC" "$CUR/style.resolved.css"
        sed -i -e 's#~/colors\.css#colors.css#g' "$CUR/style.resolved.css"
        printf '@import url("colors.css");\n' | cat - "$CUR/style.resolved.css" > "$CUR/.tmp.css"
        mv -f "$CUR/.tmp.css" "$CUR/style.resolved.css"
        chmod 0644 "$CUR/style.resolved.css"
    else
        printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
    fi
  '';

  # Waybar via systemd user service (do NOT autostart via Hyprland exec-once)
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;
}
