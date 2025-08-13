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
  # Waybar (pure: variant picked at runtime via ~/.config/waybar/current/)
  ################################
  # Install the complete themes tree (read-only link to store)
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";

  # Global fallbacks (used if a theme/variant lacks these files)
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source    = "${waybarDir}/colors.css";

  # Stable top-level config that includes the *resolved* files in current/
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      // Load files that our helper populates inside ~/.config/waybar/current/
      "include": [
        "~/.config/waybar/current/config.jsonc",
        "~/.config/waybar/current/modules.jsonc"
      ]
    }
  '';

  # IMPORTANT: only import the resolved CSS (never raw variant CSS)
  xdg.configFile."waybar/style.css".text = ''
    /* Always use the preprocessed CSS produced in ~/.config/waybar/current/ */
    @import url("current/style.resolved.css");
  '';

  # Ensure ~/.config/waybar/current/ is a directory (not a symlink) and seed safe defaults.
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CFG="$HOME/.config/waybar"
    BASE="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG"
    # Replace legacy symlink with a directory
    if [ -L "$CUR" ]; then
      rm -f "$CUR"
    fi
    mkdir -p "$CUR"

    pick_first() { for p in "$@"; do [ -e "$p" ] && { printf '%s\n' "$p"; return 0; }; done; return 1; }

    DEF="$BASE/default"
    MOD_GLOBAL="$CFG/modules.jsonc"
    COL_GLOBAL="$CFG/colors.css"

    CFG_SRC="$(pick_first "$DEF/config.jsonc")"
    MOD_SRC="$(pick_first "$DEF/modules.jsonc" "$MOD_GLOBAL")"
    CSS_SRC="$(pick_first "$DEF/style.css" "$DEF/style-custom.css")"
    COL_SRC="$(pick_first "$DEF/colors.css" "$COL_GLOBAL")"

    [ -n "$CFG_SRC" ] && ln -sfn "$CFG_SRC" "$CUR/config.jsonc"
    [ -n "$MOD_SRC" ] && ln -sfn "$MOD_SRC" "$CUR/modules.jsonc"
    [ -n "$COL_SRC" ] && ln -sfn "$COL_SRC" "$CUR/colors.css" || : > "$CUR/colors.css"

    # Build a safe resolved CSS that never references ~/colors.css
    if [ -n "$CSS_SRC" ]; then
      sed -E '
        s#@import[[:space:]]+url\((["'"'"']?)~/colors\.css\1\);[[:space:]]*##g;
        s#~/colors\.css#colors.css#g;
      ' "$CSS_SRC" > "$CUR/style.resolved.css"
      # Ensure the palette is available even if the original CSS never imported it
      if ! grep -Eq '(^|[/"'\''])colors\.css([/"'\'']|$)' "$CUR/style.resolved.css"; then
        printf '@import url("colors.css");\n' | cat - "$CUR/style.resolved.css" > "$CUR/.tmp.css" && mv "$CUR/.tmp.css" "$CUR/style.resolved.css"
      fi
    else
      : > "$CUR/style.resolved.css"
    fi
  '';

  # Waybar via systemd user service (do NOT autostart via Hyprland exec-once)
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;

}