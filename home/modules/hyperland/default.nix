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

  # Ensure ~/.config/waybar/current/ is a directory and seed safe defaults.
  # Run AFTER linkGeneration so ~/.config/waybar/themes exists.
  # Ensure ~/.config/waybar/current/ is a directory and seed safe defaults.
  # Run AFTER linkGeneration so ~/.config/waybar/themes exists.
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["linkGeneration"] ''
    CFG="$HOME/.config/waybar"
    BASE="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG"
    # Replace any legacy symlink with a real directory
    [ -L "$CUR" ] && rm -f "$CUR"
    mkdir -p "$CUR"

    # Default sources (best effort)
    DEF="$BASE/default"
    MOD_GLOBAL="$CFG/modules.jsonc"
    COL_GLOBAL="$CFG/colors.css"

    # Link config.jsonc (optional if present)
    if [ -e "$DEF/config.jsonc" ]; then
        ln -sfn "$DEF/config.jsonc" "$CUR/config.jsonc"
    fi

    # Link modules.jsonc with fallback to global
    if   [ -e "$DEF/modules.jsonc" ]; then
        ln -sfn "$DEF/modules.jsonc" "$CUR/modules.jsonc"
    elif [ -e "$MOD_GLOBAL" ]; then
        ln -sfn "$MOD_GLOBAL" "$CUR/modules.jsonc"
    fi

    # Link colors.css with fallback; if none exists, create an empty file
    if   [ -e "$DEF/colors.css" ]; then
        ln -sfn "$DEF/colors.css" "$CUR/colors.css"
    elif [ -e "$COL_GLOBAL" ]; then
        ln -sfn "$COL_GLOBAL" "$CUR/colors.css"
    else
        : > "$CUR/colors.css"
    fi

    # Pick a default CSS source
    CSS_SRC=""
    if   [ -e "$DEF/style.css" ]; then
        CSS_SRC="$DEF/style.css"
    elif [ -e "$DEF/style-custom.css" ]; then
        CSS_SRC="$DEF/style-custom.css"
    fi

    # Build a safe resolved CSS that never pulls from ~/colors.css or /home/*/colors.css
    if [ -n "$CSS_SRC" ]; then
        cp -f "$CSS_SRC" "$CUR/style.resolved.css"

        # Remove any parent-import of style.css to prevent recursion during rebuilds
        sed -i -E '/@import.*\.\.\/style\.css/d' "$CUR/style.resolved.css"


        # 1) Remove ANY @import url(...colors.css) line (tilde or absolute path)
        sed -i -E "/@import[[:space:]]+url\\((['\\\"]?)[^)]*colors\\.css\\1\\)/d" "$CUR/style.resolved.css"

        # 2) Rewrite stray references to colors.css under ~ or /home/* to relative
        sed -i -E 's#~/colors\.css#colors.css#g; s#/home/[^/]+/colors\.css#colors.css#g' "$CUR/style.resolved.css"

        # 3) Prepend exactly one safe import to the local palette
        printf '@import url("colors.css");\n' | cat - "$CUR/style.resolved.css" > "$CUR/.tmp.css"
        mv -f "$CUR/.tmp.css" "$CUR/style.resolved.css"
    else
        printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
    fi
    chmod 0644 "$CUR/style.resolved.css"
  '';

  # Waybar via systemd user service (do NOT autostart via Hyprland exec-once)
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;

  ################################
  # Rofi (static default; pure)
  ################################
  xdg.configFile."rofi/config.rasi".source = "${rofiThemePath}/config.rasi";
  xdg.configFile."rofi/colors.rasi".source = "${rofiThemePath}/colors.rasi";

  ################################
  # Hyprpaper defaults
  ################################
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${wallpaperTargetDir}/default.png
    wallpaper = ,${wallpaperTargetDir}/default.png
    splash = false
  '';

  # Default wallpaper + waypaper config
  xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";
  xdg.configFile."waypaper".source = "${hyprDir}/waypaper";

  ################################
  # Scripts & helper installation
  ################################
  # Ensure ~/.local/bin is on PATH
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];

  # Helper under ~/.local/lib/waybar-theme/
  home.file.".local/lib/waybar-theme/helper-functions.sh".text =
    builtins.readFile ./scripts/helper-functions.sh;
  home.file.".local/lib/waybar-theme/helper-functions.sh".executable = true;

  # Switch/pick scripts under ~/.local/bin/
  home.file.".local/bin/waybar-switch-theme".text =
    builtins.readFile ./scripts/waybar-switch-theme.sh;
  home.file.".local/bin/waybar-switch-theme".executable = true;

  home.file.".local/bin/waybar-pick-theme".text =
    builtins.readFile ./scripts/waybar-pick-theme.sh;
  home.file.".local/bin/waybar-pick-theme".executable = true;
}
