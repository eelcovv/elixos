{
  config,
  pkgs,
  lib,
  ...
}: let
  waybarDir = ./.;
  scriptsDir = ./scripts;
in {
  home.packages = with pkgs; [rofi-wayland swaynotificationcenter dunst];

  # CLI scripts
  home.file.".local/bin/waybar-switch-theme" = {
    source = scriptsDir + "/waybar-switch-theme.sh";
    executable = true;
  };
  home.file.".local/bin/waybar-pick-theme" = {
    source = scriptsDir + "/waybar-pick-theme.sh";
    executable = true;
  };

  # Config & thema’s
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";
  xdg.configFile."waybar/modules.jsonc".source = "${waybarDir}/modules.jsonc";
  xdg.configFile."waybar/colors.css".source = "${waybarDir}/colors.css";

  # Top-level config importeert altijd current/
  xdg.configFile."waybar/config.jsonc".text = ''
    { "include": [ "~/.config/waybar/current/config.jsonc",
                   "~/.config/waybar/current/modules.jsonc" ] }
  '';
  xdg.configFile."waybar/style.css".text = ''@import url("current/style.resolved.css");'';

  # Bootstrap current/ éénmalig en voorspelbaar
  home.activation.initWaybarCurrent = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    CFG="$HOME/.config/waybar"; BASE="$CFG/themes"; CUR="$CFG/current"
    mkdir -p "$CFG"; rm -f "$CUR"; mkdir -p "$CUR"
    DEF="$BASE/default"
    [ -e "$DEF/config.jsonc" ] && ln -sfn "$DEF/config.jsonc" "$CUR/config.jsonc"
    if   [ -e "$DEF/modules.jsonc" ]; then ln -sfn "$DEF/modules.jsonc" "$CUR/modules.jsonc"
    elif [ -e "$CFG/modules.jsonc" ]; then ln -sfn "$CFG/modules.jsonc" "$CUR/modules.jsonc"; fi
    if   [ -e "$DEF/colors.css" ]; then ln -sfn "$DEF/colors.css" "$CUR/colors.css"
    elif [ -e "$CFG/colors.css" ]; then ln -sfn "$CFG/colors.css" "$CUR/colors.css"; else : > "$CUR/colors.css"; fi
    CSS_SRC=""
    if   [ -e "$DEF/style.css" ]; then CSS_SRC="$DEF/style.css"
    elif [ -e "$DEF/style-custom.css" ]; then CSS_SRC="$DEF/style-custom.css"; fi
    if [ -n "$CSS_SRC" ]; then
      cp -f "$CSS_SRC" "$CUR/style.resolved.css"
      sed -i -E '/@import.*\.\.\/style\.css/d;/@import.*colors\.css/d' "$CUR/style.resolved.css"
      printf '@import url("colors.css");\n' | cat - "$CUR/style.resolved.css" > "$CUR/.tmp.css"
      mv -f "$CUR/.tmp.css" "$CUR/style.resolved.css"
    else
      printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
    fi
    chmod 0644 "$CUR/style.resolved.css"
  '';

  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false; # <— belangrijk
}
