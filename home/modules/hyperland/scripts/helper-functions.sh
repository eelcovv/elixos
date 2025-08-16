#!/usr/bin/env bash
# Waybar theme helper (safe to source).
# - Copies config/style/colors with cascade (variant -> theme -> default)
# - If ~/.config/waybar is read-only (Home Manager), falls back to a mutable dir
#   (XDG_STATE_HOME/waybar-theme) and restarts Waybar with -c/-s to those files.

set -euo pipefail

# --- Paths --------------------------------------------------------------------
WAYBAR_DIR="${WAYBAR_DIR:-$HOME/.config/waybar}"
WAYBAR_THEMES_DIR="${WAYBAR_THEMES_DIR:-$HOME/.config/waybar/themes}"
DEFAULT_FAMILY="${DEFAULT_FAMILY:-default}"
WAYBAR_MUTABLE_DIR_DEFAULT="${XDG_STATE_HOME:-$HOME/.local/state}/waybar-theme"
WAYBAR_MUTABLE_DIR="${WAYBAR_MUTABLE_DIR:-$WAYBAR_MUTABLE_DIR_DEFAULT}"

# --- Globals ------------------------------------------------------------------
_theme_dir=""
_var_dir=""
_def_dir=""
_active_target="$WAYBAR_DIR"   # waar we nu naartoe schrijven (kan naar MUTABLE vallen)

_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2; }
_exists_file() { [[ -f "$1" ]]; }
_exists_dir()  { [[ -d "$1" ]]; }

_pick_first_file() {
  local f; for f in "$@"; do [[ -f "$f" ]] && { printf '%s\n' "$f"; return 0; }; done
  return 1
}

# --- Resolve token ------------------------------------------------------------
_resolve() {
  local token="$1"
  local family variant kind
  if [[ "$token" == */* ]]; then
    family="${token%%/*}"; variant="${token#*/}"; kind="variant"
  else
    family="$token"; variant=""; kind="single"
  fi
  local base="$WAYBAR_THEMES_DIR"
  local theme_dir="$base/$family"
  local var_dir=""; [[ -n "$variant" ]] && var_dir="$theme_dir/$variant"
  local def_dir="$base/$DEFAULT_FAMILY"
  _debug "_resolve: kind=$kind theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"
  printf '%s\n%s\n%s\n%s\n' "$kind" "$theme_dir" "$var_dir" "$def_dir"
}

_ensure() {
  local token="$1"
  _debug "ensure: base=$WAYBAR_THEMES_DIR token=$token"
  local parts=(); mapfile -t parts < <(_resolve "$token")
  (( ${#parts[@]} == 4 )) || { echo "ERROR: internal resolve failed (got ${#parts[@]} parts)" >&2; return 1; }
  local kind="${parts[0]}"; local theme_dir="${parts[1]}"; local var_dir="${parts[2]}"; local def_dir="${parts[3]}"
  [[ -d "$theme_dir" ]] || { echo "ERROR: Theme family not found: $theme_dir" >&2; return 1; }
  [[ -z "$var_dir" || -d "$var_dir" ]] || { echo "ERROR: Variant not found: $var_dir" >&2; return 1; }
  [[ -d "$def_dir" ]] || { echo "ERROR: Default theme not found: $def_dir" >&2; return 1; }
  _theme_dir="$theme_dir"; _var_dir="$var_dir"; _def_dir="$def_dir"
  _debug "ensure: _theme_dir=$_theme_dir"; _debug "ensure: _var_dir=$_var_dir"; _debug "ensure: _def_dir=$_def_dir"
  _debug "kind=$kind token=$token"
}

# --- Pickers ------------------------------------------------------------------
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

# --- Writable target selection ------------------------------------------------
_is_writable_dir() {
  local d="$1"
  [[ -d "$d" ]] || return 1
  ( set -o noclobber; : > "$d/.wb_writable_test_$$" ) 2>/dev/null || return 1
  rm -f "$d/.wb_writable_test_$$" 2>/dev/null || true
  return 0
}

_choose_target_dir() {
  # Kies schrijfdoel: liefst WAYBAR_DIR, anders WAYBAR_MUTABLE_DIR
  if _is_writable_dir "$WAYBAR_DIR"; then
    _active_target="$WAYBAR_DIR"
  else
    mkdir -p "$WAYBAR_MUTABLE_DIR"
    _active_target="$WAYBAR_MUTABLE_DIR"
  fi
  _debug "target dir chosen: $_active_target"
}

# --- Apply files --------------------------------------------------------------
_apply_theme_files() {
  _choose_target_dir
  local target="$_active_target"
  mkdir -p "$target"

  local css cfg col
  if css="$(_pick_stylesheet)"; then
    cp -f -- "$css" "$target/style.css"
    _debug "using style: $css -> $target/style.css"
  else
    : > "$target/style.css" || true
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
    : > "$target/colors.css" || true
    _debug "no colors.css found; wrote empty (or skipped if RO)"
  fi
}

# --- Waybar reload / restart --------------------------------------------------
_reload_waybar() {
  if pgrep -x waybar >/dev/null 2>&1; then
    if [[ "$_active_target" == "$WAYBAR_DIR" ]]; then
      # Config/Style op de standaard locatie -> hot reload
      pkill -USR2 waybar || true
    else
      # We gebruiken een alternate pad: nette restart met -c/-s
      pkill -TERM waybar || true
      sleep 0.2
      ( waybar -c "$_active_target/config" -s "$_active_target/style.css" >/dev/null 2>&1 & disown ) || true
    fi
  else
    # Geen Waybar actief: start met juiste paden
    if [[ "$_active_target" == "$WAYBAR_DIR" ]]; then
      ( waybar >/dev/null 2>&1 & disown ) || true
    else
      ( waybar -c "$_active_target/config" -s "$_active_target/style.css" >/dev/null 2>&1 & disown ) || true
    fi
  fi
}

# --- Public API ---------------------------------------------------------------
switch_theme() {
  local token
  if [[ $# == 1 ]]; then
    token="$1"
  elif [[ $# == 2 ]]; then
    token="$1/$2"
  else
    echo "Usage: switch_theme THEME[/VARIANT] | switch_theme THEME VARIANT" >&2
    return 2
  fi
  _ensure "$token" || return 1
  _apply_theme_files
  _reload_waybar
  echo "Waybar theme: Applied: $token (target=$_active_target)"
}

list_themes() {
  local base="$WAYBAR_THEMES_DIR" fam vdir
  while IFS= read -r -d '' famdir; do
    fam="$(basename "$famdir")"
    [[ "$fam" == .* ]] && continue
    [[ "$fam" == assets ]] && continue
    local marker=""
    if _pick_first_file "$famdir/style.css" "$famdir/style-custom.css" >/dev/null; then
      marker="(root)"
    fi
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
  WAYBAR_DIR           Default config dir (read-only is OK)
  WAYBAR_THEMES_DIR    Themes root (default: ~/.config/waybar/themes)
  DEFAULT_FAMILY       Fallback family (default: default)
  WAYBAR_MUTABLE_DIR   Writable overlay (default: \$XDG_STATE_HOME/waybar-theme)
  WAYBAR_THEME_DEBUG   Set 1 for debug logs
EOF
}

main() {
  if [[ $# -eq 0 ]]; then print_help; exit 2; fi
  case "${1:-}" in
    --help|-h)  print_help ;;
    --list)     list_themes ;;
    --apply)    shift; switch_theme "$@" ;;
    *)          switch_theme "$@" ;;
  esac
}

# Only run main when executed directly, not when sourced
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

