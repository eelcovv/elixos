{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.; # module root met waybar/{themes,colors.css,modules.jsonc}
  scriptsDir = ./scripts; # map met je waybar scripts
  rofiRoot = ./rofi; # optioneel: rofi thema’s bij Waybar
  rofiThemePath =
    if builtins.pathExists "${rofiRoot}/themes/default"
    then "${rofiRoot}/themes/default"
    else rofiRoot;
in {
  ################################
  # Packages (Waybar + notificaties + Rofi voor pickers)
  ################################
  home.packages = with pkgs; [
    rofi-wayland
    swaynotificationcenter
    dunst
    # Waybar zelf via programs.waybar
  ];

  ################################
  # Waybar themes & config (pure: select variant via ~/.config/waybar/current/)
  ################################
  # Schip themes de Nix store in als read-only boom
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";

  # Globale fallbacks
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

  # Top-level config include de resolved files in current/
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "include": [
        "~/.config/waybar/current/config.jsonc",
        "~/.config/waybar/current/modules.jsonc"
      ]
    }
  '';

  # Altijd de voorverwerkte CSS importeren
  xdg.configFile."waybar/style.css".text = ''
    @import url("current/style.resolved.css");
  '';

  # current/ initializer (linkt defaults en bouwt style.resolved.css)
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

    if [ -e "$DEF/config.jsonc" ]; then
      ln -sfn "$DEF/config.jsonc" "$CUR/config.jsonc"
    fi

    if   [ -e "$DEF/modules.jsonc" ]; then
      ln -sfn "$DEF/modules.jsonc" "$CUR/modules.jsonc"
    elif [ -e "$MOD_GLOBAL" ]; then
      ln -sfn "$MOD_GLOBAL" "$CUR/modules.jsonc"
    fi

    if   [ -e "$DEF/colors.css" ]; then
      ln -sfn "$DEF/colors.css" "$CUR/colors.css"
    elif [ -e "$COL_GLOBAL" ]; then
      ln -sfn "$COL_GLOBAL" "$CUR/colors.css"
    else
      : > "$CUR/colors.css"
    fi

    CSS_SRC=""
    if   [ -e "$DEF/style.css" ]; then
      CSS_SRC="$DEF/style.css"
    elif [ -e "$DEF/style-custom.css" ]; then
      CSS_SRC="$DEF/style-custom.css"
    fi

    if [ -n "$CSS_SRC" ]; then
      cp -f "$CSS_SRC" "$CUR/style.resolved.css"
      sed -i -E '/@import.*\.\.\/style\.css/d' "$CUR/style.resolved.css"
      sed -i -E '/@import.*colors\.css/d' "$CUR/style.resolved.css"
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
  # Rofi (voor theme pickers e.d., onder Waybar-module)
  ################################
  # Expose de thema-tree
  xdg.configFile."rofi/themes".source = "${rofiRoot}/themes";

  # Fallbacks (wanneer theme-bestanden ontbreken)
  xdg.configFile."rofi/wallpaper.rasi" =
    if builtins.pathExists "${rofiThemePath}/wallpaper.rasi"
    then {source = "${rofiThemePath}/wallpaper.rasi";}
    else {text = ''* { current-image: none; }'';};

  xdg.configFile."rofi/font.rasi" =
    if builtins.pathExists "${rofiThemePath}/font.rasi"
    then {source = "${rofiThemePath}/font.rasi";}
    else {text = ''* { font: "Fira Sans 11"; }'';};

  xdg.configFile."rofi/spacing.rasi".text = ''
    * { spacing: 2px; padding: 2px; margin: 0px; }
  '';

  xdg.configFile."rofi/colors.rasi" =
    if builtins.pathExists "${rofiThemePath}/colors.rasi"
    then {source = "${rofiThemePath}/colors.rasi";}
    else {
      text = ''
        * {
          background: #1e1e2e;
          foreground: #cdd6f4;
          color5:     #89b4fa;
          color11:    #f9e2af;
        }
      '';
    };

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

  # Laat Waybar module de Rofi top-level config beheren
  home.sessionVariables.ROFI_CONFIG = "${config.xdg.configHome}/rofi/config.rasi";
  xdg.configFile."rofi/config.rasi".text = ''
    @import "${config.xdg.configHome}/rofi/_patched/config.rasi"
  '';

  # Patch het theme config-bestand zodat imports altijd resolvable zijn
  home.activation.rofiPatch = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    CFG="$HOME/.config/rofi"
    mkdir -p "$CFG/_patched"
    SRC="${rofiThemePath}/config.rasi"

    if [ -e "$SRC" ]; then
      install -m 0644 -D "$SRC" "$CFG/_patched/config.rasi"
      chmod u+w "$CFG/_patched/config.rasi"

      sed -i -E "s#@import[[:space:]]+(url\\()?['\\\"]?[^'\\\")]*wallpaper\\.rasi['\\\"]?\\)?;#@import \"$CFG/wallpaper.rasi\";#g" "$CFG/_patched/config.rasi"
      sed -i -E "s#@import[[:space:]]+(url\\()?['\\\"]?[^'\\\")]*font\\.rasi['\\\"]?\\)?;#@import \"$CFG/font.rasi\";#g"         "$CFG/_patched/config.rasi"
      sed -i -E "s#@import[[:space:]]+(url\\()?['\\\"]?[^'\\\")]*colors\\.rasi['\\\"]?\\)?;#@import \"$CFG/colors.rasi\";#g"     "$CFG/_patched/config.rasi"
      sed -i -E "s#@import[[:space:]]+(url\\()?['\\\"]?[^'\\\")]*border\\.rasi['\\\"]?\\)?;#@import \"$CFG/border.rasi\";#g"     "$CFG/_patched/config.rasi"
      sed -i -E "s#@import[[:space:]]+(url\\()?['\\\"]?[^'\\\")]*border-radius\\.rasi['\\\"]?\\)?;#@import \"$CFG/border-radius.rasi\";#g" "$CFG/_patched/config.rasi"

      sed -i -E "s#@import[[:space:]]+(url\\()?['\\\"]?([^/][^'\\\")]*\\.rasi)['\\\"]?\\)?;#@import \"${rofiThemePath}/\\2\";#g" "$CFG/_patched/config.rasi"
      printf '\n@import "%s/overrides.rasi";\n' "$CFG" >> "$CFG/_patched/config.rasi"
    else
      printf '@theme "gruvbox-dark"\n' > "$CFG/_patched/config.rasi"
    fi
  '';

  ################################
  # Waybar scripts (nu onder waybar/scripts)
  ################################
  # Helper onder ~/.local/lib/waybar-theme/
  home.file.".local/lib/waybar-theme/helper-functions.sh" = {
    source = scriptsDir + "/helper-functions.sh";
    executable = true;
  };

  # Switch/pick scripts onder ~/.local/bin/
  home.file.".local/bin/waybar-switch-theme" = {
    source = scriptsDir + "/waybar-switch-theme.sh";
    executable = true;
  };
  home.file.".local/bin/waybar-pick-theme" = {
    source = scriptsDir + "/waybar-pick-theme.sh";
    executable = true;
  };
}
