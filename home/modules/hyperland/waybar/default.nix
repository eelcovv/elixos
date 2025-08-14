{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.; # Root of the Waybar module (themes, colors.css, modules.jsonc)
  scriptsDir = ./scripts; # Directory containing Waybar scripts
  rofiRoot = ./rofi; # Optional: Rofi themes for Waybar

  rofiThemePath =
    if builtins.pathExists "${rofiRoot}/themes/default"
    then "${rofiRoot}/themes/default"
    else rofiRoot;

  # Patch scripts so they source the shared Hyprland helper
  patchHelper = path: let
    orig = builtins.readFile path;
  in
    lib.replaceStrings
    [
      "source \"~/.local/lib/waybar-theme/helper-functions.sh\""
      "source \"$HOME/.local/lib/waybar-theme/helper-functions.sh\""
      "source ~/.local/lib/waybar-theme/helper-functions.sh"
    ]
    [
      "source \"$HOME/.config/hypr/scripts/helper-functions.sh\""
      "source \"$HOME/.config/hypr/scripts/helper-functions.sh\""
      "source \"$HOME/.config/hypr/scripts/helper-functions.sh\""
    ]
    orig;
in {
  ################################
  # Packages for Waybar, Rofi, and notifications
  ################################
  home.packages = with pkgs; [
    rofi-wayland
    swaynotificationcenter
    dunst
  ];

  ################################
  # Waybar themes and configuration
  ################################
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

  # Top-level Waybar config includes files from current/
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "include": [
        "~/.config/waybar/current/config.jsonc",
        "~/.config/waybar/current/modules.jsonc"
      ]
    }
  '';
  # Always import the preprocessed CSS in current/
  xdg.configFile."waybar/style.css".text = ''
    @import url("current/style.resolved.css");
  '';

  # Initialize ~/.config/waybar/current/
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["linkGeneration"] ''
    CFG="$HOME/.config/waybar"
    BASE="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG"
    [ -L "$CUR" ] && rm -f "$CUR"
    mkdir -p "$CUR"

    DEF="$BASE/default"
    MOD_GLOBAL="$CFG/modules.jsonc"
    COL_GLOBAL="$CFG/colors.css"

    [ -e "$DEF/config.jsonc" ] && ln -sfn "$DEF/config.jsonc" "$CUR/config.jsonc"

    if   [ -e "$DEF/modules.jsonc" ]; then ln -sfn "$DEF/modules.jsonc" "$CUR/modules.jsonc"
    elif [ -e "$MOD_GLOBAL" ]; then       ln -sfn "$MOD_GLOBAL" "$CUR/modules.jsonc"
    fi

    if   [ -e "$DEF/colors.css" ]; then ln -sfn "$DEF/colors.css" "$CUR/colors.css"
    elif [ -e "$COL_GLOBAL" ]; then     ln -sfn "$COL_GLOBAL" "$CUR/colors.css"
    else                                : > "$CUR/colors.css"
    fi

    CSS_SRC=""
    if   [ -e "$DEF/style.css" ]; then CSS_SRC="$DEF/style.css"
    elif [ -e "$DEF/style-custom.css" ]; then CSS_SRC="$DEF/style-custom.css"
    fi

    if [ -n "$CSS_SRC" ]; then
      cp -f "$CSS_SRC" "$CUR/style.resolved.css"
      sed -i -E '/@import.*\.\.\/style\.css/d' "$CUR/style.resolved.css"
      sed -i -E '/@import.*colors\.css/d'      "$CUR/style.resolved.css"
      printf '@import url("colors.css");\n' | cat - "$CUR/style.resolved.css" > "$CUR/.tmp.css"
      mv -f "$CUR/.tmp.css" "$CUR/style.resolved.css"
    else
      printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
    fi
    chmod 0644 "$CUR/style.resolved.css"
  '';

  ################################
  # Waybar via systemd user service
  ################################
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = true;

  ################################
  # Rofi (theme management for Waybar)
  ################################
  home.sessionVariables.ROFI_CONFIG = "${config.xdg.configHome}/rofi/config.rasi";
  xdg.configFile."rofi/themes".source = "${rofiRoot}/themes";

  xdg.configFile."rofi/wallpaper.rasi" =
    if builtins.pathExists "${rofiThemePath}/wallpaper.rasi"
    then {source = "${rofiThemePath}/wallpaper.rasi";}
    else {text = ''* { current-image: none; }'';};

  xdg.configFile."rofi/font.rasi" =
    if builtins.pathExists "${rofiThemePath}/font.rasi"
    then {source = "${rofiThemePath}/font.rasi";}
    else {text = ''* { font: "Fira Sans 11"; }'';};

  xdg.configFile."rofi/spacing.rasi".text = ''* { spacing: 2px; padding: 2px; margin: 0px; }'';

  xdg.configFile."rofi/colors.rasi" =
    if builtins.pathExists "${rofiThemePath}/colors.rasi"
    then {source = "${rofiThemePath}/colors.rasi";}
    else {text = ''* { background: #1e1e2e; foreground: #cdd6f4; color5: #89b4fa; color11: #f9e2af; }'';};

  xdg.configFile."rofi/border.rasi" =
    if builtins.pathExists "${rofiThemePath}/border.rasi"
    then {source = "${rofiThemePath}/border.rasi";}
    else {text = ''* { border-width: 2; }'';};

  xdg.configFile."rofi/border-radius.rasi" =
    if builtins.pathExists "${rofiThemePath}/border-radius.rasi"
    then {source = "${rofiThemePath}/border-radius.rasi";}
    else {text = ''* { border-radius: 8px; }'';};

  xdg.configFile."rofi/overrides.rasi".text = ''
    * {}
    window, mainbox, inputbar, listview, element, button, textbox, message, mode-switcher { background-image: none; }
  '';
  xdg.configFile."rofi/config.rasi".text = ''
    @import "${config.xdg.configHome}/rofi/_patched/config.rasi"
  '';
  home.activation.rofiPatch = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    CFG="$HOME/.config/rofi"
    mkdir -p "$CFG/_patched"
    SRC="${rofiThemePath}/config.rasi"
    if [ -e "$SRC" ]; then
      install -m 0644 -D "$SRC" "$CFG/_patched/config.rasi"
      chmod u+w "$CFG/_patched/config.rasi"
      sed -i -E "s#@import.*wallpaper\\.rasi.*;#@import \"$CFG/wallpaper.rasi\";#g"       "$CFG/_patched/config.rasi"
      sed -i -E "s#@import.*font\\.rasi.*;#@import \"$CFG/font.rasi\";#g"                 "$CFG/_patched/config.rasi"
      sed -i -E "s#@import.*colors\\.rasi.*;#@import \"$CFG/colors.rasi\";#g"             "$CFG/_patched/config.rasi"
      sed -i -E "s#@import.*border\\.rasi.*;#@import \"$CFG/border.rasi\";#g"             "$CFG/_patched/config.rasi"
      sed -i -E "s#@import.*border-radius\\.rasi.*;#@import \"$CFG/border-radius.rasi\";#g" "$CFG/_patched/config.rasi"
      sed -i -E "s#@import[[:space:]]+(url\\()?['\\\"]?([^/][^'\\\")]*\\.rasi)['\\\"]?\\)?;#@import \"${rofiThemePath}/\\2\";#g" "$CFG/_patched/config.rasi"
      printf '\n@import "%s/overrides.rasi";\n' "$CFG" >> "$CFG/_patched/config.rasi"
    else
      printf '@theme "gruvbox-dark"\n' > "$CFG/_patched/config.rasi"
    fi
  '';

  ################################
  # Waybar scripts (patched to use shared Hyprland helper)
  ################################
  home.file.".local/bin/waybar-switch-theme" = {
    text = patchHelper (scriptsDir + "/waybar-switch-theme.sh");
    executable = true;
  };
  home.file.".local/bin/waybar-pick-theme" = {
    text = patchHelper (scriptsDir + "/waybar-pick-theme.sh");
    executable = true;
  };
}
