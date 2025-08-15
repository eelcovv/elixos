{
  config,
  pkgs,
  lib,
  ...
}: let
  # Module root must contain: ./themes, ./scripts, optional ./colors.css and ./modules.jsonc
  waybarDir  = ./.;
  scriptsDir = ./scripts;

  # Resolves to "~/.config/waybar"
  cfgPath = "${config.xdg.configHome}/waybar";
in {
  ##########################################################################
  # Packages used by the picker (menu + notifications)
  ##########################################################################
  home.packages = with pkgs; [
    rofi-wayland
    swaynotificationcenter
    dunst
  ];

  ##########################################################################
  # Install helper-driven switcher scripts into ~/.local/bin
  ##########################################################################
  home.file.".local/bin/waybar-switch-theme" = {
    source     = scriptsDir + "/waybar-switch-theme.sh";
    executable = true;
  };
  home.file.".local/bin/waybar-pick-theme" = {
    source     = scriptsDir + "/waybar-pick-theme.sh";
    executable = true;
  };

  ##########################################################################
  # Expose the themes tree from the repo (read-only via Nix store)
  ##########################################################################
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";

  # OPTIONAL: if you keep shared fallbacks in the module root, expose them:
  # (Safe to omit if your themes provide their own)
  xdg.configFile."waybar/colors.css"    = lib.mkIf (builtins.pathExists (waybarDir + "/colors.css")) {
    source = waybarDir + "/colors.css";
  };
  xdg.configFile."waybar/modules.jsonc" = lib.mkIf (builtins.pathExists (waybarDir + "/modules.jsonc")) {
    source = waybarDir + "/modules.jsonc";
  };

  ##########################################################################
  # IMPORTANT: Do NOT manage top-level Waybar files via xdg.configFile
  # (config.jsonc, style.css, modules.jsonc, colors.css). We want your
  # helper to freely relink them at runtime. We only bootstrap them IF MISSING.
  ##########################################################################
  home.activation.bootstrapWaybarIfMissing = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    set -eu
    CFG="${cfgPath}"
    THEMES="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG" "$CUR"

    # Pick a reliable default theme variant if nothing is initialized yet.
    # Prefer "default" folder; otherwise pick the first style.css we can find.
    choose_variant() {
      if [ -e "$THEMES/default/style.css" ]; then
        echo "default"
        return 0
      fi
      # Find first theme/variant with style.css
      local first
      first="$(find -L "$THEMES" -mindepth 2 -maxdepth 2 -type f -name 'style.css' | head -n1 || true)"
      if [ -n "$first" ]; then
        # Strip "$THEMES/" prefix and "/style.css" suffix -> "theme/variant"
        echo "${first#$THEMES/}" | sed 's#/style\.css$##'
        return 0
      fi
      echo ""
      return 1
    }

    # Only bootstrap if nothing has ever been written by scripts:
    if [ ! -e "$CUR/style.resolved.css" ]; then
      variant="$(choose_variant || true)"
      if [ -n "$variant" ]; then
        # Build an initial style.resolved.css from the chosen variant
        var_dir="$THEMES/$variant"
        theme_dir="${var_dir%/*}"    # "themes/<theme>"

        css_src=""
        if   [ -e "$var_dir/style.css" ]; then css_src="$var_dir/style.css"
        elif [ -e "$var_dir/style-custom.css" ]; then css_src="$var_dir/style-custom.css"
        fi

        # Prepare colors.css fallback
        if   [ -e "$var_dir/colors.css" ]; then ln -sfn "$var_dir/colors.css" "$CUR/colors.css"
        elif [ -e "$theme_dir/colors.css" ]; then ln -sfn "$theme_dir/colors.css" "$CUR/colors.css"
        elif [ -e "$CFG/colors.css" ]; then ln -sfn "$CFG/colors.css" "$CUR/colors.css"
        else : > "$CUR/colors.css"; fi

        if [ -n "$css_src" ]; then
          cp -f "$css_src" "$CUR/style.resolved.css"
          sed -i -E '/@import.*\.\.\/style\.css/d; /@import.*colors\.css/d' "$CUR/style.resolved.css"
          printf '@import url("colors.css");\n' | cat - "$CUR/style.resolved.css" > "$CUR/.tmp.css"
          mv -f "$CUR/.tmp.css" "$CUR/style.resolved.css"
        else
          printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
        fi

        # Minimal config/modules to keep Waybar happy until user switches
        if   [ -e "$var_dir/config.jsonc" ]; then ln -sfn "$var_dir/config.jsonc" "$CUR/config.jsonc"
        elif [ -e "${theme_dir}/config.jsonc" ]; then ln -sfn "${theme_dir}/config.jsonc" "$CUR/config.jsonc"
        elif [ -e "$THEMES/default/config.jsonc" ]; then ln -sfn "$THEMES/default/config.jsonc" "$CUR/config.jsonc"
        else printf '{ "modules-left": [], "modules-center": [], "modules-right": [] }\n' > "$CUR/config.jsonc"; fi

        if   [ -e "$var_dir/modules.jsonc" ]; then ln -sfn "$var_dir/modules.jsonc" "$CUR/modules.jsonc"
        elif [ -e "${theme_dir}/modules.jsonc" ]; then ln -sfn "${theme_dir}/modules.jsonc" "$CUR/modules.jsonc"
        elif [ -e "$CFG/modules.jsonc" ]; then ln -sfn "$CFG/modules.jsonc" "$CUR/modules.jsonc"
        else printf '{}\n' > "$CUR/modules.jsonc"; fi
      fi
    fi

    # Ensure top-level Waybar entry points point at current/*
    # These files are NOT owned by Nix (so your script can relink them later).
    [ -e "$CFG/config.jsonc" ]        || ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
    [ -e "$CFG/modules.jsonc" ]       || ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
    [ -e "$CFG/colors.css" ]          || ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
    [ -e "$CFG/style.css" ]           || ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"
  '';

  ##########################################################################
  # Waybar is enabled but NOT started by systemd (Hyprland starts it)
  ##########################################################################
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;

  ##########################################################################
  # Ensure ~/.local/bin is in PATH
  ##########################################################################
  home.sessionPath = lib.mkAfter [ "$HOME/.local/bin" ];
}

