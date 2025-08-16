#!/usr/bin/env bash
# Common helpers for Waybar theme switching (Hyprland setup).
# Robust against Nix-store symlinks. Supports:
#   - "theme" (single-level, style.css at theme root)
#   - "theme/variant" (two-level; variant may or may not have its own style.css)
#
# Usage:
#   helper-function.sh THEME[/VARIANT]
#   helper-function.sh THEME VARIANT
#   helper-function.sh --apply THEME[/VARIANT]
#   helper-function.sh --list
#   helper-function.sh --help
#
# Env:
#   WAYBAR_THEME_DEBUG=1  # extra debug logging

set -Eeuo pipefail

# --- Global state (initialize to avoid 'unbound variable' with set -u) ---
_theme_dir=""
_var_dir=""
_def_dir=""
_kind=""

# Enable extra logging by exporting: WAYBAR_THEME_DEBUG=1
_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

notify() {
  local title="${1:-}"; shift || true
  local body="${*:-}"
  [[ -n "$title" ]] && printf '%s: %s\n' "$title" "$body"
  command -v logger >/dev/null 2>&1 && logger -t waybar-theme -- "$title: $body"
  command -v notify-send >/dev/null 2>&1 && notify-send "$title" "$body" || true
}

_have_file() {
  local p="$1"
  [[ -e "$p" || -L "$p" ]] && return 0
  local r
  r="$(readlink -f -- "$p" 2>/dev/null || true)"
  [[ -n "$r" && -e "$r" ]] && return 0
  return 1
}

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

_resolve_theme_paths() {
  local base="$1"
  local token="$2"

  _theme_dir=""
  _var_dir=""
  _def_dir="$base/default"
  _kind="unknown"

  if [[ "$token" == */* ]]; then
    _var_dir="$base/$token"
    _theme_dir="$base/${token%%/*}"
    if [[ -d "$_var_dir" ]]; then
      _kind="variant"
      _debug "_resolve: kind=$_kind theme_dir=$_theme_dir var_dir=$_var_dir def_dir=$_def_dir"
      return 0
    fi
  else
    _theme_dir="$base/$token"
    if [[ -d "$_theme_dir" ]]; then
      _kind="single"
      _debug "_resolve: kind=$_kind theme_dir=$_theme_dir def_dir=$_def_dir"
      return 0
    fi
  fi

  _debug "_resolve: unknown token=$token base=$base"
  return 1
}

ensure_theme_variant() {
  local base="$1"
  local token="$2"

  if ! _resolve_theme_paths "$base" "$token"; then
    echo "Unknown theme: $token"
    return 1
  fi
  local kind="$_kind"

  _debug "ensure: base=$base token=$token"
  _debug "ensure: _theme_dir=$_theme_dir"
  _debug "ensure: _var_dir=$_var_dir"
  _debug "ensure: _def_dir=$_def_dir"

  local have=()

  case "$kind" in
    single)
      _have_file "$_theme_dir/style.css"        && have+=("$_theme_dir/style.css")
      _have_file "$_theme_dir/style-custom.css" && have+=("$_theme_dir/style-custom.css")
      _have_file "$_def_dir/style.css"          && have+=("$_def_dir/style.css")
      _have_file "$_def_dir/style-custom.css"   && have+=("$_def_dir/style-custom.css")
      if ((${#have[@]}==0)); then
        echo "Theme '$token' heeft geen style.css (en ook geen default/style.css)."
        return 1
      fi
      ;;
    variant)
      _have_file "$_var_dir/style.css"          && have+=("$_var_dir/style.css")
      _have_file "$_var_dir/style-custom.css"   && have+=("$_var_dir/style-custom.css")
      _have_file "$_theme_dir/style.css"        && have+=("$_theme_dir/style.css")
      _have_file "$_theme_dir/style-custom.css" && have+=("$_theme_dir/style-custom.css")
      _have_file "$_def_dir/style.css"          && have+=("$_def_dir/style.css")
      _have_file "$_def_dir/style-custom.css"   && have+=("$_def_dir/style-custom.css")
      if ((${#have[@]}==0)); then
        echo "Variant '$token' heeft geen style.css (noch parent theme, noch default)."
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
  local token="$1"

  local cfg="$HOME/.config/waybar"
  local base="$cfg/themes"
  local cur="$cfg/current"

  local cfg_src mod_src css_src col_src
  local mod_global="$cfg/modules.jsonc"

  # Mogelijke global colors
  local col_global1="$cfg/colors.css"
  local col_global2="$base/colors.css"

  ensure_theme_variant "$base" "$token" || return 1
  local kind="$_kind"

  local theme_dir="$_theme_dir"
  local var_dir="$_var_dir"
  local def_dir="$_def_dir"

  mkdir -p "$cur"

  _debug "kind=$kind token=$token"
  _debug "theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"

  # config.jsonc
  if [[ "$kind" == "variant" ]]; then
    cfg_src="$(_pick_first_existing "$var_dir/config.jsonc" "$theme_dir/config.jsonc" "$def_dir/config.jsonc")" || true
  else
    cfg_src="$(_pick_first_existing "$theme_dir/config.jsonc" "$def_dir/config.jsonc")" || true
  fi

  # modules.jsonc
  if [[ "$kind" == "variant" ]]; then
    mod_src="$(_pick_first_existing "$var_dir/modules.jsonc" "$theme_dir/modules.jsonc" "$def_dir/modules.jsonc" "$mod_global")" || true
  else
    mod_src="$(_pick_first_existing "$theme_dir/modules.jsonc" "$def_dir/modules.jsonc" "$mod_global")" || true
  fi

  # style.css
  if [[ "$kind" == "variant" ]]; then
    css_src="$(_pick_first_existing "$var_dir/style.css" "$var_dir/style-custom.css" "$theme_dir/style.css" "$theme_dir/style-custom.css" "$def_dir/style.css" "$def_dir/style-custom.css")" || true
  else
    css_src="$(_pick_first_existing "$theme_dir/style.css" "$theme_dir/style-custom.css" "$def_dir/style.css" "$def_dir/style-custom.css")" || true
  fi

  # colors.css
  if [[ "$kind" == "variant" ]]; then
    col_src="$(_pick_first_existing "$var_dir/colors.css" "$theme_dir/colors.css")" || true
  else
    col_src="$(_pick_first_existing "$theme_dir/colors.css")" || true
  fi
  [[ -z "${col_src:-}" ]] && col_src="$(_pick_first_existing "$col_global1" "$col_global2")" || true

  # symlinks
  [[ -n "${cfg_src:-}" ]] && ln -sfn "$cfg_src" "$cur/config.jsonc"
  [[ -n "${mod_src:-}" ]] && ln -sfn "$mod_src" "$cur/modules.jsonc"

  # colors.css
  rm -f "$cur/colors.css" 2>/dev/null || true
  if [[ -n "${col_src:-}" && -f "$col_src" ]]; then
    if [[ "$col_src" == "$col_global1" || "$col_src" == "$col_global2" ]]; then
      cp -f --remove-destination "$col_src" "$cur/colors.css"
    else
      ln -sfn "$col_src" "$cur/colors.css"
    fi
  else
    : > "$cur/colors.css"
  fi

  # style.resolved.css
  if [[ -n "${css_src:-}" ]]; then
    cp -f "$css_src" "$cur/style.resolved.css"
    sed -i -E '/@import.*colors\.css/d' "$cur/style.resolved.css"
    sed -i -E "s#@import[[:space:]]+(url\()?['\"]?\.\./style\.css['\"]?\)?;#@import url(\"$theme_dir/style.css\");#g" "$cur/style.resolved.css"
    sed -i -E "s#@import[[:space:]]+(url\()?['\"]?\.\./([^'\"\\)]+)['\"]?\)?;#@import url(\"$theme_dir/\2\");#g" "$cur/style.resolved.css"
    printf '@import url("colors.css");\n' | cat - "$cur/style.resolved.css" > "$cur/.tmp.css"
    mv -f "$cur/.tmp.css" "$cur/style.resolved.css"
  else
    printf '@import url("colors.css");\n' > "$cur/style.resolved.css"
  fi

  chmod 0644 "$cur/style.resolved.css"

  ln -sfn "$cur/config.jsonc"       "$cfg/config.jsonc"
  ln -sfn "$cur/modules.jsonc"      "$cfg/modules.jsonc"
  ln -sfn "$cur/style.resolved.css" "$cfg/style.css"
  ln -sfn "$cur/colors.css"         "$cfg/colors.css"

  pkill -USR2 waybar 2>/dev/null || true

  notify "Waybar theme" "Applied: $token"
}

print_help() {
  cat <<'EOF'
Waybar theme helper

Usage:
  helper-function.sh THEME[/VARIANT]
  helper-function.sh THEME VARIANT
  helper-function.sh --apply THEME[/VARIANT]
  helper-function.sh --list
  helper-function.sh --help
EOF
}

main() {
  local cfg="$HOME/.config/waybar"
  local base="$cfg/themes"
  mkdir -p "$cfg" "$base"

  if (($# == 0)); then
    print_help; exit 1
  fi

  case "${1:-}" in
    --help|-h) print_help; exit 0 ;;
    --list)    list_theme_variants "$base"; exit 0 ;;
    --apply)   shift ;;
  esac

  local token
  if (($# >= 2)) && [[ "$1" != */* ]]; then
    token="$1/$2"
  else
    token="$1"
  fi

  _debug "main: token=$token"
  switch_theme "$token"
}

# alleen uitvoeren als dit bestand direct is aangeroepen, niet bij 'source'
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
