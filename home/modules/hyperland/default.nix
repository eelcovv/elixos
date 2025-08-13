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
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

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

  # Stable stylesheet that imports from current/
  xdg.configFile."waybar/style.css".text = ''
    /* Delegate styling to the resolved current files */
    @import url("current/style.css");
    @import url("current/colors.css");
  '';

  # Ensure ~/.config/waybar/current/ is a directory (not a symlink).
  # Create it if missing, or replace a legacy symlink with a directory.
  # Also seed it with default fallbacks on first install to avoid a broken bar.
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["writeBoundary"] ''
    CFG="$HOME/.config/waybar"
    BASE="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG"

    if [ -L "$CUR" ]; then
      rm -f "$CUR"
    fi
    mkdir -p "$CUR"

    # Seed defaults only if files are not present yet
    pick_first() {
      # echo the first existing path among arguments
      for p in "$@"; do
        [ -e "$p" ] && { printf '%s\n' "$p"; return 0; }
      done
      return 1
    }

    # Defaults
    DEF="$BASE/default"
    MOD_GLOBAL="$CFG/modules.jsonc"
    COL_GLOBAL="$CFG/colors.css"

    # Populate missing links with safe fallbacks
    [ -e "$CUR/config.jsonc" ] || ln -sfn "$(pick_first "$DEF/config.jsonc")" "$CUR/config.jsonc" || true
    [ -e "$CUR/modules.jsonc" ] || ln -sfn "$(pick_first "$DEF/modules.jsonc" "$MOD_GLOBAL")" "$CUR/modules.jsonc" || true
    [ -e "$CUR/style.css"    ] || ln -sfn "$(pick_first "$DEF/style.css" "$DEF/style-custom.css")" "$CUR/style.css" || true
    [ -e "$CUR/colors.css"   ] || ln -sfn "$(pick_first "$DEF/colors.css" "$COL_GLOBAL")" "$CUR/colors.css" || true
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

  # Default wallpaper + waypaper
  xdg.configFile."wallpapers/default.png".source = "${wallpaperDir}/nixos.png";
  xdg.configFile."waypaper".source = "${hyprDir}/waypaper";

  ################################
  # Scripts & helper installation
  ################################
  # Add ~/.local/bin to PATH
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
