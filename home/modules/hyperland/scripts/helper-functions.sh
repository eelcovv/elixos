#!/usr/bin/env bash
# Common helpers for Waybar theme switching (Hyprland setup).
# Robust against Nix-store symlinks and supports both:
#   - "theme" (single-level, style.css at theme root)
#   - "theme/variant" (two-level, style.css inside the variant folder)

# --- Global state (initialize to avoid 'unbound variable' with set -u) ---
_theme_dir=""   # e.g., $BASE/ml4w
_var_dir=""     # e.g., $BASE/ml4w/dark
_def_dir=""     # e.g., $BASE/default

# Enable extra logging by exporting:  WAYBAR_THEME_DEBUG=1
_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

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

# Safely check for file existence through symlinks (Nix store etc.)
_have_file() {
  # Args: <path>
  local p="$1"
  [[ -e "$p" || -L "$p" ]] && return 0
  local r
  r="$(readlink -f -- "$p" 2>/dev/null || true)"
  [[ -n "$r" && -e "$r" ]] && return 0
  return 1
}

# Return first existing file from the given candidates (echo path; 0 if found)
_pick_first_existing() {
  local cand
  for cand in "$@"; do
    if _have_file "$cand"; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  return 1
}

# List selectable themes (single-level and two-level), excluding "assets"
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
      _debug "_resolve: kind=variant theme_dir=$_theme_dir var_dir=$_var_dir"
      echo "variant"
      return 0
    fi
  else
    # single-level theme form
    _theme_dir="$base/$token"
    if [[ -d "$_theme_dir" ]]; then
      _debug "_resolve: kind=single theme_dir=$_theme_dir"
      echo "single"
      return 0
    fi
  fi

  _debug "_resolve: unknown token=$token"
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
      if ! _have_file "$_theme_dir/style.css" && ! _have_file "$_theme_dir/style-custom.css"; then
        echo "Theme '$token' has no style.css"
        return 1
      fi
      ;;
    variant)
      if ! _have_file "$_var_dir/style.css" && ! _have_file "$_var_dir/style-custom.css"; then
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

  _debug "kind=$kind token=$token"
  _debug "theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"

  # Resolve config.jsonc
  if [[ "$kind" == "variant" ]]; then
    cfg_src="$(_pick_first_existing \
      "$var_dir/config.jsonc" \
      "$theme_dir/config.jsonc" \
      "$def_dir/config.jsonc")"
  else
    cfg_src="$(_pick_first_existing \
      "$theme_dir/config.jsonc" \
      "$def_dir/config.jsonc")"
  fi
  [[ -n "${cfg_src:-}" ]] || cfg_src=""

  # Resolve modules.jsonc
  if [[ "$kind" == "variant" ]]; then
    mod_src="$(_pick_first_existing \
      "$var_dir/modules.jsonc" \
      "$theme_dir/modules.jsonc" \
      "$def_dir/modules.jsonc" \
      "$mod_global")"
  else
    mod_src="$(_pick_first_existing \
      "$theme_dir/modules.jsonc" \
      "$def_dir/modules.jsonc" \
      "$mod_global")"
  fi
  [[ -n "${mod_src:-}" ]] || mod_src=""

  # Resolve style.css
  if [[ "$kind" == "variant" ]]; then
    css_src="$(_pick_first_existing \
      "$var_dir/style.css" \
      "$var_dir/style-custom.css" \
      "$def_dir/style.css" \
      "$def_dir/style-custom.css")"
  else
    css_src="$(_pick_first_existing \
      "$theme_dir/style.css" \
      "$theme_dir/style-custom.css" \
      "$def_dir/style.css" \
      "$def_dir/style-custom.css")"
  fi
  [[ -n "${css_src:-}" ]] || css_src=""

  # Resolve colors.css
  if [[ "$kind" == "variant" ]]; then
    col_src="$(_pick_first_existing \
      "$var_dir/colors.css" \
      "$theme_dir/colors.css" \
      "$col_global")"
  else
    col_src="$(_pick_first_existing \
      "$theme_dir/colors.css" \
      "$col_global")"
  fi
  [[ -n "${col_src:-}" ]] || col_src=""

  _debug "cfg_src=$cfg_src"
  _debug "mod_src=$mod_src"
  _debug "css_src=$css_src"
  _debug "col_src=$col_src"

  # Link config/modules into current/
  [[ -n "$cfg_src" ]] && ln -sfn "$cfg_src" "$cur/config.jsonc"
  [[ -n "$mod_src" ]] && ln -sfn "$mod_src" "$cur/modules.jsonc"

  # Make current/colors.css safe (avoid self-symlink to $cfg/colors.css)
  rm -f "$cur/colors.css" 2>/dev/null || true
  if [[ -n "$col_src" ]]; then
    if [[ "$col_src" != "$cfg/colors.css" ]]; then
      ln -sfn "$col_src" "$cur/colors.css"
    else
      cp -f --remove-destination "$col_src" "$cur/colors.css"
    fi
  else
    : > "$cur/colors.css"
  fi

  # Build current/style.resolved.css (prepend one colors import; strip nested imports)
  if [[ -n "$css_src" ]]; then
    cp -f "$css_src" "$cur/style.resolved.css"
    if command -v perl >/dev/null 2>&1; then
      perl -0777 -pe 's/^\s*@import[^\n]*colors\.css[^\n]*\n//gmi' -i "$cur/style.resolved.css"
    else
      sed -i -E '/@import.*colors\.css/d' "$cur/style.resolved.css"
    fi
    # Rewrite any "../foo.css" imports to the theme root we resolved
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

  notify "Waybar theme" "Applied: $token"
}

