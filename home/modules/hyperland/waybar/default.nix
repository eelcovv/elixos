{
  config,
  pkgs,
  lib,
  ...
}: let
  # Path to this module directory (must contain ./themes, ./colors.css, ./modules.jsonc, ./scripts)
  waybarDir = ./.;

  # Directory in this module that contains our two theme scripts
  scriptsDir = ./scripts;

  # Resolve to "~/.config/waybar" at runtime
  cfgPath = "${config.xdg.configHome}/waybar";
in {
  ##########################################################################
  # Packages (menus + notifications used by the scripts)
  ##########################################################################
  home.packages = with pkgs; [
    rofi-wayland
    swaynotificationcenter
    dunst
  ];

  ##########################################################################
  # Install the theme-switcher scripts declaratively into ~/.local/bin
  ##########################################################################
  home.file.".local/bin/waybar-switch-theme" = {
    source = scriptsDir + "/waybar-switch-theme.sh";
    executable = true;
  };
  home.file.".local/bin/waybar-pick-theme" = {
    source = scriptsDir + "/waybar-pick-theme.sh";
    executable = true;
  };

  ##########################################################################
  # Provide themes and global Waybar snippets from the repo
  ##########################################################################
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

  ##########################################################################
  # Top-level Waybar config & stylesheet (absolute paths; no "~")
  ##########################################################################
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "include": [
        "${cfgPath}/current/config.jsonc",
        "${cfgPath}/current/modules.jsonc"
      ]
    }
  '';

  # Always import the preprocessed CSS in current/
  xdg.configFile."waybar/style.css".text = ''
    @import url("${cfgPath}/current/style.resolved.css");
  '';

  ##########################################################################
  # Initialize ~/.config/waybar/current on each activation
  # - Links config.jsonc / modules.jsonc / colors.css from the selected theme
  #   (or from global fallbacks) into current/
  # - Builds a style.resolved.css that first imports colors.css
  ##########################################################################
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    CFG="${cfgPath}"
    BASE="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG"
    rm -f "$CUR"
    mkdir -p "$CUR"

    DEF="$BASE/default"
    MOD_GLOBAL="$CFG/modules.jsonc"
    COL_GLOBAL="$CFG/colors.css"

    # config.jsonc (prefer theme/default; otherwise minimal)
    if [ -e "$DEF/config.jsonc" ]; then
      ln -sfn "$DEF/config.jsonc" "$CUR/config.jsonc"
    else
      printf '{ "modules-left": [], "modules-center": [], "modules-right": [] }\n' > "$CUR/config.jsonc"
    fi

    # modules.jsonc (prefer theme/default; fallback to global)
    if   [ -e "$DEF/modules.jsonc" ]; then ln -sfn "$DEF/modules.jsonc" "$CUR/modules.jsonc"
    elif [ -e "$MOD_GLOBAL" ]; then         ln -sfn "$MOD_GLOBAL"      "$CUR/modules.jsonc"
    else                                    printf '{}\n' > "$CUR/modules.jsonc"
    fi

    # colors.css (prefer theme/default; fallback to global; otherwise empty)
    if   [ -e "$DEF/colors.css" ]; then ln -sfn "$DEF/colors.css" "$CUR/colors.css"
    elif [ -e "$COL_GLOBAL" ]; then     ln -sfn "$COL_GLOBAL"     "$CUR/colors.css"
    else                                : > "$CUR/colors.css"
    fi

    # Build style.resolved.css (prepend colors import, strip nested imports)
    CSS_SRC=""
    if   [ -e "$DEF/style.css" ]; then CSS_SRC="$DEF/style.css"
    elif [ -e "$DEF/style-custom.css" ]; then CSS_SRC="$DEF/style-custom.css"
    fi

    if [ -n "$CSS_SRC" ]; then
      cp -f "$CSS_SRC" "$CUR/style.resolved.css"
      sed -i -E '/@import.*\.\.\/style\.css/d; /@import.*colors\.css/d' "$CUR/style.resolved.css"
      printf '@import url("colors.css");\n' | cat - "$CUR/style.resolved.css" > "$CUR/.tmp.css"
      mv -f "$CUR/.tmp.css" "$CUR/style.resolved.css"
    else
      printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
    fi

    chmod 0644 "$CUR/style.resolved.css"
  '';

  ##########################################################################
  # Waybar is enabled but NOT managed by systemd (Hyprland starts it)
  ##########################################################################
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;

  ##########################################################################
  # Ensure ~/.local/bin is in PATH (for the scripts above)
  ##########################################################################
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}
