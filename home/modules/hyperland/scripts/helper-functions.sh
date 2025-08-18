#!/usr/bin/env bash
# Waybar theme helper – schrijft naar ~/.config/waybar/current/
set -euo pipefail

# --- Padconfig ---------------------------------------------------------------
WAYBAR_DIR="${WAYBAR_DIR:-$HOME/.config/waybar}"                 # -> ~/.config/waybar
WAYBAR_THEMES_DIR="${WAYBAR_THEMES_DIR:-$HOME/.config/waybar/themes}"
DEFAULT_FAMILY="${DEFAULT_FAMILY:-default}"
STATE_BASE_DEFAULT="${XDG_STATE_HOME:-$HOME/.local/state}/waybar-theme"
STATE_BASE="${WAYBAR_MUTABLE_DIR:-$STATE_BASE_DEFAULT}"          # fallback als ~/.config/waybar/current niet schrijfbaar

# --- Globals -----------------------------------------------------------------
_theme_dir=""
_var_dir=""
_def_dir=""
_target_base=""   # .../current (schrijfdoel)

_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2; }

# --- Utils -------------------------------------------------------------------
_exists_file(){ [[ -f "$1" ]]; }
_pick_first_file(){
  local f
  for f in "$@"; do
    [[ -f "$f" ]] && { printf '%s\n' "$f"; return 0; }
  done
  return 1
}

_is_writable_dir() {
  local d="$1"
  [[ -d "$d" ]] || return 1
  ( set -o noclobber; : > "$d/.wb_writable_test_$$" ) 2>/dev/null || return 1
  rm -f "$d/.wb_writable_test_$$" 2>/dev/null || true
  return 0
}

_safe_write() { # _safe_write DEST < content
  local dest="$1"
  rm -f -- "$dest" 2>/dev/null || true
  umask 022
  local tmp
  tmp="$(mktemp "${dest}.XXXXXX")"
  cat >"$tmp"
  mv -f -- "$tmp" "$dest"
}

_safe_install() { # _safe_install SRC DEST
  local src="$1" dest="$2"
  rm -f -- "$dest" 2>/dev/null || true
  install -m 0644 -- "$src" "$dest"
}

# --- Resolve -----------------------------------------------------------------
_resolve() {
  local token="$1" family variant kind
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
  [[ -n "$variant" ]] && var_dir="$theme_dir/$variant"
  local def_dir="$base/$DEFAULT_FAMILY"

  _debug "_resolve: kind=$kind theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"
  printf '%s\n%s\n%s\n%s\n' "$kind" "$theme_dir" "$var_dir" "$def_dir"
}

# --- Top-level symlinks die HM gebruikt -------------------------------------
_update_top_level_links() {
  ln -sfn "$_target_base/style.resolved.css" "$WAYBAR_DIR/style.css"
  ln -sfn "$_target_base/config.jsonc"       "$WAYBAR_DIR/config"
  ln -sfn "$_target_base/modules.jsonc"      "$WAYBAR_DIR/modules.jsonc"
  ln -sfn "$_target_base/colors.css"         "$WAYBAR_DIR/colors.css"
}



_ensure() {
  local token="$1"
  _debug "ensure: base=$WAYBAR_THEMES_DIR token=$token"

  # Run resolver and capture all lines
  local out
  if ! out="$(_resolve "$token")"; then
    echo "ERROR: internal resolve failed (resolve exited non-zero)" >&2
    return 1
  fi

  # Split into lines (exactly 4 expected)
  local lines=() line
  while IFS= read -r line; do
    lines+=("$line")
  done <<< "$out"

  if (( ${#lines[@]} != 4 )); then
    echo "ERROR: internal resolve failed (expected 4 lines, got ${#lines[@]})" >&2
    _debug "resolve out was: >>>$out<<<"
    return 1
  fi

  local kind="${lines[0]}"
  local theme_dir="${lines[1]}"
  local var_dir="${lines[2]}"
  local def_dir="${lines[3]}"

  [[ -d "$theme_dir" ]] || { echo "ERROR: Theme family not found: $theme_dir" >&2; return 1; }
  [[ -z "$var_dir" || -d "$var_dir" ]] || { echo "ERROR: Variant not found: $var_dir" >&2; return 1; }
  [[ -d "$def_dir" ]] || { echo "ERROR: Default theme not found: $def_dir" >&2; return 1; }

  _theme_dir="$theme_dir"
  _var_dir="$var_dir"
  _def_dir="$def_dir"
  _debug "kind=$kind theme_dir=$_theme_dir var_dir=$_var_dir def_dir=$_def_dir"
}

# --- Target select: .../current ----------------------------------------------
_choose_target_base() {
  local primary="$WAYBAR_DIR/current"
  local alt="$STATE_BASE/current"
  if _is_writable_dir "$WAYBAR_DIR" && { [[ -d "$primary" ]] || mkdir -p "$primary"; }; then
    _target_base="$primary"
  else
    mkdir -p "$alt"
    _target_base="$alt"
  fi
  _debug "target base chosen: $_target_base"
}

# --- Pickers (cascade) -------------------------------------------------------
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
    "${_def_dir}/colors.css" \
    "${WAYBAR_DIR}/colors.css"
}

_pick_config() {
  _pick_first_file \
    "${_var_dir}/config.jsonc" "${_var_dir}/config" \
    "${_theme_dir}/config.jsonc" "${_theme_dir}/config" \
    "${_def_dir}/config.jsonc" "${_def_dir}/config"
}

_pick_modules() {
  _pick_first_file \
    "${_var_dir}/modules.jsonc" \
    "${_theme_dir}/modules.jsonc" \
    "${WAYBAR_DIR}/modules.jsonc"
}

# --- Build style.resolved.css -------------------------------------------------
_build_style_resolved() {
  local src_css="$1" out_css="$2"
  printf '@import url("colors.css");\n' > "$out_css"
  if [[ -f "$src_css" ]]; then
    # strip dubbele imports; houd het bestand zelf verder intact
    sed -E '/@import.*\.\.\/style\.css/d; /@import.*colors\.css/d' "$src_css" >> "$out_css"
  fi
}

# --- Apply -------------------------------------------------------------------
_apply_theme_files() {
  _choose_target_base
  local css cfg mod col

  # colors.css
  if col="$(_pick_colors)"; then
    _safe_install "$col" "$_target_base/colors.css"
    _debug "colors: $col -> $_target_base/colors.css"
  else
    _safe_write "$_target_base/colors.css" <<<"/* empty colors */"
    _debug "colors: none found → wrote empty"
  fi

  # config.jsonc
  if cfg="$(_pick_config)"; then
    _safe_install "$cfg" "$_target_base/config.jsonc"
    _debug "config: $cfg -> $_target_base/config.jsonc"
  else
    _safe_write "$_target_base/config.jsonc" <<<'{ "modules-left": [], "modules-center": [], "modules-right": [] }'
    _debug "config: none → wrote minimal"
  fi

  # modules.jsonc
  if mod="$(_pick_modules)"; then
    _safe_install "$mod" "$_target_base/modules.jsonc"
    _debug "modules: $mod -> $_target_base/modules.jsonc"
  else
    _safe_write "$_target_base/modules.jsonc" <<<"{}"
    _debug "modules: none → wrote {}"
  fi

  # style.resolved.css
  if css="$(_pick_stylesheet)"; then
    _build_style_resolved "$css" "$_target_base/style.resolved.css"
    _debug "style: built from $css -> $_target_base/style.resolved.css"
  else
    _safe_write "$_target_base/style.resolved.css" <<<'@import url("colors.css");'
    echo "WARN: no stylesheet found; wrote colors-only style" >&2
  fi
}

# --- Process detect & reload --------------------------------------------------
_waybar_pids() {
  # Match wrapper & direct, met/zonder args
  pgrep -f '(^|/)\.?waybar(-wrapped)?([[:space:]]|$)' 2>/dev/null || true
}


_reload_waybar() {
  if systemctl --user is-active --quiet waybar-managed.service; then
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
  else
    # fallback als unit niet actief is (handmatige start)
    pkill -USR2 -x waybar 2>/dev/null || true
  fi
}


# --- Public API ---------------------------------------------------------------
switch_theme() {
  local token
  if   [[ $# == 1 ]]; then token="$1"
  elif [[ $# == 2 ]]; then token="$1/$2"
  else
    echo "Usage: switch_theme THEME[/VARIANT] | THEME VARIANT" >&2
    return 2
  fi

  _ensure "$token" || return 1
  _apply_theme_files
  _update_top_level_links
  _reload_waybar
  echo "Waybar theme: Applied: $token (target=$_target_base)"
}

list_themes() {
  local base="$WAYBAR_THEMES_DIR" fam vdir
  while IFS= read -r -d '' famdir; do
    fam="$(basename "$famdir")"
    [[ "$fam" == .* ]] && continue
    [[ "$fam" == assets ]] && continue

    local has_root=""
    _pick_first_file "$famdir/style.css" "$famdir/style-custom.css" >/dev/null && has_root=1

    local any_var=0
    while IFS= read -r -d '' vdir; do
      _pick_first_file "$vdir/style.css" "$vdir/style-custom.css" >/dev/null || continue
      if [[ -z "$has_root" && $any_var -eq 0 ]]; then
        printf '%s/\n' "$fam"
      fi
      printf '%s/%s\n' "$fam" "$(basename "$vdir")"
      any_var=1
    done < <(find -L "$famdir" -mindepth 1 -maxdepth 1 -type d -print0)

    [[ -n "$has_root" ]] && printf '%s\n' "$fam"
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
  WAYBAR_DIR           (~/.config/waybar)
  WAYBAR_THEMES_DIR    (~/.config/waybar/themes)
  DEFAULT_FAMILY       (default)
  WAYBAR_MUTABLE_DIR   (~/.local/state/waybar-theme)
  WAYBAR_THEME_DEBUG   (1 for debug)
EOF
}

main() {
  if [[ $# -eq 0 ]]; then
    print_help
    exit 2
  fi
  case "${1:-}" in
    --help|-h)  print_help ;;
    --list)     list_themes ;;
    --apply)    shift; switch_theme "$@" ;;
    *)          switch_theme "$@" ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

