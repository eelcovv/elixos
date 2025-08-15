#!/usr/bin/env bash
# Common helpers for Waybar theme switching (Hyprland setup).
# This file lives in ~/.config/hypr/scripts via Home-Manager.

notify() {
  local title="$1"; shift
  local body="${*:-}"
  printf '%s: %s\n' "$title" "$body"
  if command -v logger >/dev/null 2>&1; then
    logger -t waybar-theme -- "$title: $body"
  fi
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body" || true
  fi
}

# List theme variants as "theme/variant" under $base (default: ~/.config/waybar/themes).
# Criteria: variant dir contains style.css or style-custom.css (config may live at theme root).
list_theme_variants() {
  local base="${1:-$HOME/.config/waybar/themes}"
  [[ -d "$base" ]] || return 0
  local IFS=$'\n'
  local hits=()
  mapfile -t hits < <(find -L "$base" \
    -mindepth 2 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) \
    -printf '%h\n' | sort -u)
  local dir rel
  for dir in "${hits[@]}"; do
    rel="${dir#$base/}"
    [[ "$rel" == */* ]] || continue
    printf '%s\n' "$rel"
  done
}

ensure_theme_variant() {
  local base="$1"
  local theme="$2"
  if [[ ! -d "$base/$theme" ]]; then
    echo "Unknown theme variant: $theme"
    return 1
  fi
  if [[ ! -f "$base/$theme/style.css" && ! -f "$base/$theme/style-custom.css" ]]; then
    echo "Variant '$theme' has no style.css"
    return 1
  fi
}

switch_theme() {
  # Args: <theme/variant>; populates ~/.config/waybar/current/* and relinks top-level files.
  local theme="$1"

  local cfg="$HOME/.config/waybar"
  local base="$cfg/themes"
  local cur="$cfg/current"
  local theme_root="${theme%%/*}"        # "ml4w" from "ml4w/dark"
  local var_dir="$base/$theme"
  local theme_dir="$base/$theme_root"
  local def_dir="$base/default"

  local mod_global="$cfg/modules.jsonc"
  local col_global="$cfg/colors.css"

  ensure_theme_variant "$base" "$theme" || return 1
  mkdir -p "$cur"

  local cfg_src mod_src css_src col_src

  # Resolve config.jsonc (variant -> theme -> default)
  if   [[ -e "$var_dir/config.jsonc" ]];   then cfg_src="$var_dir/config.jsonc"
  elif [[ -e "$theme_dir/config.jsonc" ]]; then cfg_src="$theme_dir/config.jsonc"
  else                                           cfg_src="$def_dir/config.jsonc"; fi

  # Resolve modules.jsonc (variant -> theme -> default -> global)
  if   [[ -e "$var_dir/modules.jsonc" ]];   then mod_src="$var_dir/modules.jsonc"
  elif [[ -e "$theme_dir/modules.jsonc" ]]; then mod_src="$theme_dir/modules.jsonc"
  elif [[ -e "$def_dir/modules.jsonc" ]];   then mod_src="$def_dir/modules.jsonc"
  else                                           mod_src="$mod_global"; fi

  # Resolve style.css (prefer variant; fallback to default)
  if   [[ -e "$var_dir/style.css" ]];        then css_src="$var_dir/style.css"
  elif [[ -e "$var_dir/style-custom.css" ]]; then css_src="$var_dir/style-custom.css"
  elif [[ -e "$def_dir/style.css" ]];        then css_src="$def_dir/style.css"
  else                                             css_src="$def_dir/style-custom.css"; fi

  # Resolve colors.css (variant -> theme -> global)
  if   [[ -e "$var_dir/colors.css" ]];   then col_src="$var_dir/colors.css"
  elif [[ -e "$theme_dir/colors.css" ]]; then col_src="$theme_dir/colors.css"
  else                                        col_src="$col_global"; fi

  # Link config/modules into current/
  [[ -n "$cfg_src" && -e "$cfg_src" ]] && ln -sfn "$cfg_src" "$cur/config.jsonc"
  [[ -n "$mod_src" && -e "$mod_src" ]] && ln -sfn "$mod_src" "$cur/modules.jsonc"

  # Make current/colors.css safe (avoid self-symlink to $cfg/colors.css)
  rm -f "$cur/colors.css" 2>/dev/null || true
  if [[ -n "$col_src" && -e "$col_src" ]]; then
    if [[ "$col_src" != "$cfg/colors.css" ]]; then
      ln -sfn "$col_src" "$cur/colors.css"
    else
      cp -f --remove-destination "$col_src" "$cur/colors.css"
    fi
  else
    : > "$cur/colors.css"
  fi

  # Build current/style.resolved.css (prepend one colors import; strip nested imports)
  if [[ -n "$css_src" && -e "$css_src" ]]; then
    cp -f "$css_src" "$cur/style.resolved.css"
    if command -v perl >/dev/null 2>&1; then
      perl -0777 -pe 's/^\s*@import[^\n]*colors\.css[^\n]*\n//gmi' -i "$cur/style.resolved.css"
    else
      sed -i -E '/@import.*colors\.css/d' "$cur/style.resolved.css"
    fi
    sed -i -E "s#@import[[:space:]]+(url\()?['\"]?\.\./style\.css['\"]?\)?;#@import url(\"$theme_dir/style.css\");#g" "$cur/style.resolved.css"
    sed -i -E "s#@import[[:space:]]+(url\()?['\"]?\.\./([^'\"\\)]+)['\"]?\)?;#@import url(\"$theme_dir/\2\");#g" "$cur/style.resolved.css"
    printf '@import url("colors.css");\n' | cat - "$cur/style.resolved.css" > "$cur/.tmp.css"
    mv -f "$cur/.tmp.css" "$cur/style.resolved.css"
  else
    printf '@import url("colors.css");\n' > "$cur/style.resolved.css"
  fi

  chmod 0644 "$cur/style.resolved.css"

  # Relink top-level entry points to current/*
  ln -sfn "$cur/config.jsonc"       "$cfg/config.jsonc"
  ln -sfn "$cur/modules.jsonc"      "$cfg/modules.jsonc"
  ln -sfn "$cur/style.resolved.css" "$cfg/style.css"
  ln -sfn "$cur/colors.css"         "$cfg/colors.css"

  # Soft-reload Waybar (do not spawn a new instance)
  pkill -USR2 waybar 2>/dev/null || true

  notify "Waybar theme" "Applied: $theme"
}

