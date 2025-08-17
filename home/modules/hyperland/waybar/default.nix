{
  config,
  pkgs,
  lib,
  ...
}: let
  # Module root must contain: ./themes, ./scripts, optional ./colors.css and ./modules.jsonc
  waybarDir = ./.;
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
    source = scriptsDir + "/waybar-switch-theme.sh";
    executable = true;
  };
  home.file.".local/bin/waybar-pick-theme" = {
    source = scriptsDir + "/waybar-pick-theme.sh";
    executable = true;
  };

  ##########################################################################
  # Expose the themes tree from the repo (read-only via Nix store)
  ##########################################################################
  xdg.configFile."waybar/themes".source = "${waybarDir}/themes";

  # OPTIONAL: global fallbacks (only if present in your repo)
  xdg.configFile."waybar/colors.css" = lib.mkIf (builtins.pathExists (waybarDir + "/colors.css")) {
    source = waybarDir + "/colors.css";
  };
  xdg.configFile."waybar/modules.jsonc" = lib.mkIf (builtins.pathExists (waybarDir + "/modules.jsonc")) {
    source = waybarDir + "/modules.jsonc";
  };

  ##########################################################################
  # REMOVE Nix-managed top-level config/style. We will always symlink to current/*
  ##########################################################################
  # (Intentionally no xdg.configFile."waybar/config.jsonc".text)
  # (Intentionally no xdg.configFile."waybar/style.css".text)

  ##########################################################################
  # Initialize ~/.config/waybar/current only if missing (do NOT overwrite)
  ##########################################################################
  home.activation.bootstrapWaybarIfMissing = lib.hm.dag.entryAfter ["linkGeneration"] ''
    set -eu
    CFG="${cfgPath}"
    THEMES="$CFG/themes"
    CUR="$CFG/current"

    mkdir -p "$CFG" "$CUR"

    choose_variant() {
      if [ -e "$THEMES/default/style.css" ]; then
        echo "default"
        return 0
      fi
      local first
      first="$(find -L "$THEMES" -mindepth 2 -maxdepth 2 -type f -name 'style.css' | head -n1 || true)"
      if [ -n "$first" ]; then
        echo "''${first#''$THEMES/}" | sed 's#/style\.css$##'
        return 0
      fi
      echo ""
      return 1
    }

    if [ ! -e "$CUR/style.resolved.css" ]; then
      variant="$(choose_variant || true)"
      if [ -n "$variant" ]; then
        var_dir="$THEMES/$variant"
        theme_dir="''${var_dir%/*}"

        css_src=""
        if   [ -e "$var_dir/style.css" ]; then css_src="$var_dir/style.css"
        elif [ -e "$var_dir/style-custom.css" ]; then css_src="$var_dir/style-custom.css"
        fi

        # colors.css cascade
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
        elif [ -e "''${theme_dir}/config.jsonc" ]; then ln -sfn "''${theme_dir}/config.jsonc" "$CUR/config.jsonc"
        elif [ -e "$THEMES/default/config.jsonc" ]; then ln -sfn "$THEMES/default/config.jsonc" "$CUR/config.jsonc"
        else printf '{ "modules-left": [], "modules-center": [], "modules-right": [] }\n' > "$CUR/config.jsonc"; fi

        if   [ -e "$var_dir/modules.jsonc" ]; then ln -sfn "$var_dir/modules.jsonc" "$CUR/modules.jsonc"
        elif [ -e "''${theme_dir}/modules.jsonc" ]; then ln -sfn "''${theme_dir}/modules.jsonc" "$CUR/modules.jsonc"
        elif [ -e "$CFG/modules.jsonc" ]; then ln -sfn "$CFG/modules.jsonc" "$CUR/modules.jsonc"
        else printf '{}\n' > "$CUR/modules.jsonc"; fi
      fi
    fi
  '';

  ##########################################################################
  # Always force top-level entry points to point at current/*
  ##########################################################################
  home.activation.waybarEntryPoints = lib.hm.dag.entryAfter ["bootstrapWaybarIfMissing"] ''
    set -eu
    CFG="${cfgPath}"
    CUR="$CFG/current"
    mkdir -p "$CFG" "$CUR"

    ln -sfn "$CUR/config.jsonc"       "$CFG/config"
    ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
    ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
    ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
    ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"
  '';

  ##########################################################################
  # Waybar is enabled but NOT started by systemd (Hyprland starts it)
  ##########################################################################
  programs.waybar.enable = true;
  programs.waybar.systemd.enable = false;

  ##########################################################################
  # Ensure ~/.local/bin is in PATH
  ##########################################################################
  home.sessionPath = lib.mkAfter ["$HOME/.local/bin"];
}
