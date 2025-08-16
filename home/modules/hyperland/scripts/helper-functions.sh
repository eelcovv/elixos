#!/usr/bin/env bash
# Helper functions for switching Waybar themes.
# Safe to 'source' from other scripts. Only executes main() when run directly.
# - Resolves theme tokens like "family" or "family/variant"
# - Copies config, style.css and (optional) colors.css with cascade:
#     variant -> theme -> default
# - Reloads Waybar cleanly: SIGUSR2 if possible; else gentle restart

set -euo pipefail

# --- Configurable paths -------------------------------------------------------
WAYBAR_DIR="${WAYBAR_DIR:-$HOME/.config/waybar}"
WAYBAR_THEMES_DIR="${WAYBAR_THEMES_DIR:-$HOME/.config/waybar/themes}"
DEFAULT_FAMILY="${DEFAULT_FAMILY:-default}"   # fallback family name

# --- Globals set by _resolve/_ensure -----------------------------------------
_theme_dir=""
_var_dir=""
_def_dir=""

_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2; }

# --- Utilities ----------------------------------------------------------------
_exists_file() { [[ -f "$1" ]]; }
_exists_dir()  { [[ -d "$1" ]]; }

# Pick first existing file from arguments; echo it and return 0, else 1.
_pick_first_file() {
  local f
  for f in "$@"; do
    [[ -f "$f" ]] && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

# --- Resolve token into directories ------------------------------------------
# Token: "family" or "family/variant"
_resolve() {
  local token="$1"

  local family variant kind
  if [[ "$token" == */* ]]; then
    family="${token%%/*}"
    variant="${token#*/}"
    kind="variant"
  else
    family="$token"
    variant=""
    kind="single"
  fi

  local base="$WAYBAR_THEMES_DIR"
  local theme_dir="$base/$family"
  local var_dir=""
  local def_dir="$base/$DEFAULT_FAMILY"

  if [[ -n "$variant" ]]; then
    var_dir="$theme_dir/$variant"
  fi

  _debug "_resolve: kind=$kind theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"
  printf '%s\0%s\0%s\0%s\n' "$kind" "$theme_dir" "$var_dir" "$def_dir"
}

# Ensure dirs and set globals
_ensure() {
  local base="$WAYBAR_THEMES_DIR" token="$1"
  _debug "ensure: base=$base token=$token"

  # shellcheck disable=SC2034
  local kind theme_dir var_dir def_dir
  IFS=$'\0' read -r -d '' kind -d '' theme_dir -d '' var_dir -d '' def_dir < <(_resolve "$token")

  if ! _exists_dir "$theme_dir"; then
    echo "ERROR: Theme family not found: $theme_dir" >&2
    return 1
  fi
  if [[ -n "$var_dir" && ! -d "$var_dir" ]]; then
    echo "ERROR: Variant not found: $var_dir" >&2
    return 1
  fi
  if ! _exists_dir "$def_dir"; then
    echo "ERROR: Default theme not found: $def_dir" >&2
    return 1
  fi

  _theme_dir="$theme_dir"
  _var_dir="$var_dir"
  _def_dir="$def_dir"
  _debug "ensure: _theme_dir=$_theme_dir"
  _debug "ensure: _var_dir=$_var_dir"
  _debug "ensure: _def_dir=$_def_dir"

  _debug "kind=$kind token=$token"
  _debug "theme_dir=$_theme_dir var_dir=$_var_dir def_dir=$_def_dir"
  return 0
}

# --- Pickers for files with cascade ------------------------------------------
_pick_stylesheet() {
  _pick_first_file \
    "${_var_dir}/style.css" "${_var_dir}/style-custom.css" \
    "${_theme_dir}/style.css" "${_theme_dir}/style-custom.css" \
    "${_def_dir}/style.css" "${_def_dir}/style-custom.css"
}

_pick_colors() {
  _pick_first_file \
    "${_var_dir}/colors.css" \
    "${_theme_dir}/colors.css" \
    "${_def_dir}/colors.css"
}

_pick_config() {
  _pick_first_file \
    "${_var_dir}/config.jsonc" "${_var_dir}/config" \
    "${_theme_dir}/config.jsonc" "${_theme_dir}/config" \
    "${_def_dir}/config.jsonc" "${_def_dir}/config"
}

# --- Apply files into ~/.config/waybar ----------------------------------------
_apply_theme_files() {
  local target="$WAYBAR_DIR"
  mkdir -p "$target"

  local css cfg col
  if css="$(_pick_stylesheet)"; then
    cp -f -- "$css" "$target/style.css"
    _debug "using style: $css -> $target/style.css"
  else
    : > "$target/style.css"
    echo "WARN: no stylesheet found (variant/theme/default)" >&2
  fi

  if cfg="$(_pick_config)"; then
    cp -f -- "$cfg" "$target/config"
    _debug "using config: $cfg -> $target/config"
  else
    echo "WARN: no config found (variant/theme/default). Keeping existing." >&2
  fi

  if col="$(_pick_colors)"; then
    cp -f -- "$col" "$target/colors.css"
    _debug "using colors: $col -> $target/colors.css"
  else
    : > "$target/colors.css"
    _debug "no colors.css found; wrote empty file"
  fi
}

# --- Waybar reload logic ------------------------------------------------------
_reload_waybar() {
  # Prefer hot-reload with USR2 (Waybar supports it). If no proc, start one.
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -USR2 waybar || true
  else
    # Start exactly one Waybar
    ( waybar >/dev/null 2>&1 & disown ) || true
  fi
}

# --- Public API ---------------------------------------------------------------
switch_theme() {
  # Accepts: THEME[/VARIANT]  OR  THEME VARIANT
  local token
  if [[ $# -eq 1 ]]; then
    token="$1"
  elif [[ $# -eq 2 ]]; then
    token="$1/$2"
  else
    echo "Usage: switch_theme THEME[/VARIANT] | switch_theme THEME VARIANT" >&2
    return 2
  fi

  _ensure "$token" || return 1
  _apply_theme_files
  _reload_waybar
  echo "Waybar theme: Applied: $token"
}

list_themes() {
  # List families and variants that actually contain styles
  local base="$WAYBAR_THEMES_DIR"
  local fam vdir
  while IFS= read -r -d '' famdir; do
    fam="$(basename "$famdir")"
    [[ "$fam" == .* ]] && continue
    [[ "$fam" == assets ]] && continue

    local marker=""
    if _pick_first_file "$famdir/style.css" "$famdir/style-custom.css" >/dev/null; then
      marker="(root)"
    fi

    # Variants
    local has_variant=0
    while IFS= read -r -d '' vdir; do
      if _pick_first_file "$vdir/style.css" "$vdir/style-custom.css" >/dev/null; then
        if [[ -z "$marker" && $has_variant -eq 0 ]]; then
          printf '%s\n' "$fam/"
        fi
        printf '%s\n' "$fam/$(basename "$vdir")"
        has_variant=1
      fi
    done < <(find -L "$famdir" -mindepth 1 -maxdepth 1 -type d -print0)

    if [[ -n "$marker" ]]; then
      printf '%s\n' "$fam"
    fi
  done < <(find -L "$base" -mindepth 1 -maxdepth 1 -type d -print0)
}

print_help() {
  cat <<EOF
Waybar theme helper

Usage:
  helper-functions.sh THEME[/VARIANT]
  helper-functions.sh THEME VARIANT
  helper-functions.sh --apply THEME[/VARIANT]
  helper-functions.sh --list
  helper-functions.sh --help

Env:
  WAYBAR_DIR           Target dir (default: ~/.config/waybar)
  WAYBAR_THEMES_DIR    Themes root (default: ~/.config/waybar/themes)
  DEFAULT_FAMILY       Fallback family (default: default)
  WAYBAR_THEME_DEBUG   Set 1 for debug logs
EOF
}

main() {
  if [[ $# -eq 0 ]]; then
    print_help
    exit 2
  fi
  case "${1:-}" in
    --help|-h)
      print_help
      ;;
    --list)
      list_themes
      ;;
    --apply)
      shift
      switch_theme "$@"
      ;;
    *)
      switch_theme "$@"
      ;;
  esac
}

# Only run main when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

