#!/usr/bin/env bash
# Common helpers for Waybar theme switching (Hyprland setup).
# Supports both "theme/variant" and single-level "theme" (style.css at theme root).

# --- Global state (must be initialized to avoid 'unbound variable' with set -u) ---
_theme_dir=""   # e.g., $BASE/ml4w
_var_dir=""     # e.g., $BASE/ml4w/dark
_def_dir=""     # e.g., $BASE/default

notify() {
  # Args: <title> [body...]
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

# List selectable themes:
# - Single-level themes:   base/<theme>/style.css
# - Two-level variants:    base/<theme>/<variant>/style.css
# Excludes any "assets" directory.
list_theme_variants() {
  local base="${1:-$HOME/.config/waybar/themes}"
  [[ -d "$base" ]] || return 0

  local IFS=$'\n'
  mapfile -t hits < <(
    { find -L "$base" -mindepth 1 -maxdepth 1 -type f -name 'style.css';
      find -L "$base" -mindepth 2 -maxdepth 2 -type f -name 'style.css'; } \
    | grep -v '/assets/' \
    | sort -u
  )

  local f rel
  for f in "${hits[@]}"; do
    rel="${f#$base/}"
    rel="${rel%/style.css}"
    [[ -n "$rel" ]] && printf '%s\n' "$rel"
  done
}

# Resolve whether token is "theme/variant" or just "theme".
# Side effects: sets global _theme_dir, _var_dir, _def_dir.
# Output (stdout): "single" | "variant" | "unknown"
_resolve_theme_paths() {
  local base="$1"
  local token="$2"

  # Reset globals to safe values every call
  _theme_dir=""
  _var_dir=""
  _def_dir="$base/default"

  if [[ "$token" == */* ]]; then
    # theme/variant form
    _var_dir="$base/$token"
    _theme_dir="$base/${token%%/*}"
    if [[ -d "$_var_dir" ]]; then
      echo "variant"
      return 0
    fi
  else
    # single-level theme form
    _theme_dir="$base/$token"
    if [[ -d "$_theme_dir" ]]; then
      echo "single"
      return 0
    fi
  fi

  echo "unknown"
  return 1
}

ensure_theme_variant() {
  # Accepts "theme" (single) or "theme/variant"
  local base="$1"
  local token="$2"

  local kind
  kind="$(_resolve_theme_paths "$base" "$token")" || {
    echo "Unknown theme: $token"
    return 1
  }

  case "$kind" in
    single)
      if [[ ! -f "$_theme_dir/style.css" && ! -f "$_theme_dir/style-custom.css" ]]; then
        echo "Theme '$token' has no style.css"
        return 1
      fi
      ;;
    variant)
      if [[ ! -f "$_var_dir/style.css" && ! -f "$_var_dir/style-custom.css" ]]; then
        echo "Variant '$token' has no style.css"
        return 1
      fi
      ;;
    *)
      echo "Invalid theme token: $token"
      return 1
      ;;
  esac
}

switch_theme() {
  # Arg: token = "theme" (single) OR "theme/variant"
  local token="$1"

  local cfg="$HOME/.config/waybar"
  local base="$cfg/themes"
  local cur="$cfg/current"

  local kind cfg_src mod_src css_src col_src
  local mod_global="$cfg/modules.jsonc"
  local col_global="$cfg/colors.css"

  # Ensure and resolve (fills _theme_dir/_var_dir/_def_dir)
  ensure_theme_variant "$base" "$token" || return 1
  kind="$(_resolve_theme_paths "$base" "$token")" || return 1

  # Copy resolved paths from globals to locals (clarity)
  local theme_dir="$_theme_dir"
  local var_dir="$_var_dir"
  local def_dir="$_def_dir"

  mkdir -p "$cur"

  # Resolve config.jsonc (prefer most specific, fall back to default)
  if [[ "$kind" == "variant" ]]; then
    if   [[ -e "$var_dir/config.jsonc" ]];   then cfg_src="$var_dir/config.jsonc"
    elif [[ -e "$theme_dir/config.jsonc" ]]; then cfg_src="$theme_dir/config.jsonc"
    else                                           cfg_src="$def_dir/config.jsonc"; fi
  else
    if   [[ -e "$theme_dir/config.jsonc" ]]; then cfg_src="$theme_dir/config.jsonc"
    else                                           cfg_src="$def_dir/config.jsonc"; fi
  fi

  # Resolve modules.jsonc (specific -> theme -> default -> global)
  if [[ "$kind" == "variant" ]]; then
    if   [[ -e "$var_dir/modules.jsonc" ]];   then mod_src="$var_dir/modules.jsonc"
    elif [[ -e "$theme_dir/modules.jsonc" ]]; then mod_src="$theme_dir/modules.jsonc"
    elif [[ -e "$def_dir/modules.jsonc" ]];   then mod_src="$def_dir/modules.jsonc"
    else                                           mod_src="$mod_global"; fi
  else
    if   [[ -e "$theme_dir/modules.jsonc" ]]; then mod_src="$theme_dir/modules.jsonc"
    elif [[ -e "$def_dir/modules.jsonc" ]];   then mod_src="$def_dir/modules.jsonc"
    else                                           mod_src="$mod_global"; fi
  fi

  # Resolve style.css (prefer most specific; fallback to default)
  if [[ "$kind" == "variant" ]]; then
    if   [[ -e "$var_dir/style.css" ]];        then css_src="$var_dir/style.css"
    elif [[ -e "$var_dir/style-custom.css" ]]; then css_src="$var_dir/style-custom.css"
    elif [[ -e "$def_dir/style.css" ]];        then css_src="$def_dir/style.css"
    else                                             css_src="$def_dir/style-custom.css"; fi
  else
    if   [[ -e "$theme_dir/style.css" ]];        then css_src="$theme_dir/style.css"
    elif [[ -e "$theme_dir/style-custom.css" ]]; then css_src="$theme_dir/style-custom.css"
    elif [[ -e "$def_dir/style.css" ]];          then css_src="$def_dir/style.css"
    else                                               css_src="$def_dir/style-custom.css"; fi
  fi

  # Resolve colors.css (specific -> theme -> global)
  if [[ "$kind" == "variant" ]]; then
    if   [[ -e "$var_dir/colors.css" ]];   then col_src="$var_dir/colors.css"
    elif [[ -e "$theme_dir/colors.css" ]]; then col_src="$theme_dir/colors.css"
    else                                        col_src="$col_global"; fi
  else
    if   [[ -e "$theme_dir/colors.css" ]]; then col_src="$theme_dir/colors.css"
    else                                        col_src="$col_global"; fi
  fi

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
    # Rewrite any "../foo.css" imports to the theme root we resolved
    sed -i -E "s#@import[[:space:]]+(url\()?['\"]?\.\./style\.css['\"]?\)?;#@import url(\"$theme_dir/style.css\");#g" "$cur/style.resolved.css"
    sed -i -E "s#@import[[:space:]]+(url\()?['\"]?\.\./([^'\"\\)]+)['\"]?\)?;#@import url(\"$theme_dir/\2\");#g" "$cur/style.resolved.css"
    printf '@import url(\"colors.css\");\n' | cat - "$cur/style.resolved.css" > "$cur/.tmp.css"
    mv -f "$cur/.tmp.css" "$cur/style.resolved.css"
  else
    printf '@import url(\"colors.css\");\n' > "$cur/style.resolved.css"
  fi

  chmod 0644 "$cur/style.resolved.css"

  # Relink top-level entry points to current/*
  ln -sfn "$cur/config.jsonc"       "$cfg/config.jsonc"
  ln -sfn "$cur/modules.jsonc"      "$cfg/modules.jsonc"
  ln -sfn "$cur/style.resolved.css" "$cfg/style.css"
  ln -sfn "$cur/colors.css"         "$cfg/colors.css"

  # Soft-reload Waybar (do not spawn a new instance)
  pkill -USR2 waybar 2>/dev/null || true

  notify "Waybar theme" "Applied: $token"
}

