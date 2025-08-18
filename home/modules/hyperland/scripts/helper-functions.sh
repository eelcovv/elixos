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
_theme_dir=""; _var_dir=""; _def_dir=""
_target_base=""   # .../current (schrijfdoel)

_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2; }

# --- Utils -------------------------------------------------------------------
_exists_file(){ [[ -f "$1" ]]; }
_pick_first_file(){ local f; for f in "$@"; do [[ -f "$f" ]] && { printf '%s\n' "$f"; return 0; }; done; return 1; }

_is_writable_dir() {
  local d="$1"
  [[ -d "$d" ]] || return 1
  ( set -o noclobber; : > "$d/.wb_writable_test_$$" ) 2>/dev/null || return 1
  rm -f "$d/.wb_writable_test_$$" 2>/dev/null || true
  return 0
}

<<<<<<< HEAD
# List variants as "theme/variant" under $base (default: ~/.config/waybar/themes).
# Criteria: variant dir contains style.css or style-custom.css. We do NOT require config.jsonc here,
# because many themes keep config.jsonc at the theme root.
list_theme_variants() {
    local base="${1:-$HOME/.config/waybar/themes}"

    [[ -d "$base" ]] || return 0

    # Follow symlinks (-L) and look exactly one level below each theme (depth 2 total)
    # for files named style.css or style-custom.css; print the parent dir of those files.
    local IFS=$'\n'
    local hits=()
    mapfile -t hits < <(find -L "$base" \
        -mindepth 2 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) \
        -printf '%h\n' | sort -u)

    # Emit relative paths "theme/variant"
    local dir rel
    for dir in "${hits[@]}"; do
        rel="${dir#$base/}"
        [[ "$rel" == */* ]] || continue
        printf '%s\n' "$rel"
    done
=======
_safe_write() { # _safe_write DEST < content
  local dest="$1"; rm -f -- "$dest" 2>/dev/null || true
  umask 022; local tmp; tmp="$(mktemp "${dest}.XXXXXX")"
  cat >"$tmp"; mv -f -- "$tmp" "$dest"
>>>>>>> backtosystemd
}

_safe_install() { # _safe_install SRC DEST
  local src="$1" dest="$2"; rm -f -- "$dest" 2>/dev/null || true
  install -m 0644 -- "$src" "$dest"
}

# --- Resolve -----------------------------------------------------------------
_resolve() {
  local token="$1" family variant kind
  if [[ "$token" == */* ]]; then family="${token%%/*}"; variant="${token#*/}"; kind="variant"
  else family="$token"; variant=""; kind="single"; fi
  local base="$WAYBAR_THEMES_DIR"
  local theme_dir="$base/$family"; local var_dir=""; [[ -n "$variant" ]] && var_dir="$theme_dir/$variant"
  local def_dir="$base/$DEFAULT_FAMILY"
  _debug "_resolve: kind=$kind theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"
  printf '%s\n%s\n%s\n%s\n' "$kind" "$theme_dir" "$var_dir" "$def_dir"
}

_ensure() {
  local token="$1"; _debug "ensure: base=$WAYBAR_THEMES_DIR token=$token"
  local p=(); if ! mapfile -t p < <(_resolve "$token"); then
    echo "ERROR: internal resolve failed (mapfile/resolve)" >&2; return 1
  fi
  (( ${#p[@]} == 4 )) || { echo "ERROR: internal resolve failed (got ${#p[@]} parts)" >&2; return 1; }
  local kind="${p[0]}" theme_dir="${p[1]}" var_dir="${p[2]}" def_dir="${p[3]}"
  [[ -d "$theme_dir" ]] || { echo "ERROR: Theme family not found: $theme_dir" >&2; return 1; }
  [[ -z "$var_dir" || -d "$var_dir" ]] || { echo "ERROR: Variant not found: $var_dir" >&2; return 1; }
  [[ -d "$def_dir" ]] || { echo "ERROR: Default theme not found: $def_dir" >&2; return 1; }
  _theme_dir="$theme_dir"; _var_dir="$var_dir"; _def_dir="$def_dir"
  _debug "kind=$kind theme_dir=$_theme_dir var_dir=$_var_dir def_dir=$_def_dir"
}

# --- Target select: .../current ----------------------------------------------
_choose_target_base() {
  local primary="$WAYBAR_DIR/current" alt="$STATE_BASE/current"
  if _is_writable_dir "$WAYBAR_DIR" && { [[ -d "$primary" ]] || mkdir -p "$primary"; }; then
    _target_base="$primary"
  else
    mkdir -p "$alt"; _target_base="$alt"
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
  # Match wrapper & direct, with/zonder args
  pgrep -f '(^|/)\.?waybar(-wrapped)?([[:space:]]|$)' 2>/dev/null || true
}

_reload_waybar() {
  local pids; pids="$(_waybar_pids || true)"
  if [[ -n "${pids//[[:space:]]/}" ]]; then
    _debug "found running waybar PIDs: $(tr '\n' ' ' <<<"$pids")"
    # Hot-reload alle actieve instances
    while read -r pid; do
      [[ -n "$pid" ]] && kill -USR2 "$pid" 2>/dev/null || true
    done <<<"$pids"
    _debug "hot reload (USR2) sent"
    # Optional: forceer single instance door extra's te sluiten (laat de laagste PID leven)
    # shellcheck disable=SC2002
    if [[ "$(echo "$pids" | wc -w)" -gt 1 ]]; then
      local keep; keep="$(echo "$pids" | tr ' ' '\n' | sort -n | head -n1)"
      while read -r pid; do
        [[ -n "$pid" && "$pid" != "$keep" ]] && kill "$pid" 2>/dev/null || true
      done <<<"$(echo "$pids" | tr ' ' '\n')"
      _debug "trimmed to single instance (kept PID $keep)"
    fi
  else
    ( waybar >/dev/null 2>&1 & disown ) || true
    _debug "waybar was not running → started"
  fi
}

# --- Public API ---------------------------------------------------------------
switch_theme() {
<<<<<<< HEAD
    # Args: <theme/variant>; populates ~/.config/waybar/current/* with best-available targets.
    local theme="$1"

    local cfg="$HOME/.config/waybar"
    local base="$cfg/themes"
    local cur="$cfg/current"
    local theme_root="${theme%%/*}"    # "ml4w" from "ml4w/light"
    local var_dir="$base/$theme"
    local theme_dir="$base/$theme_root"
    local def_dir="$base/default"

    local mod_global="$cfg/modules.jsonc"
    local col_global="$cfg/colors.css"

    ensure_theme_variant "$base" "$theme" || return 1
    mkdir -p "$cur"

    # Resolve with fallbacks: variant -> theme -> default -> global
    local cfg_src mod_src css_src col_src

    if [[ -e "$var_dir/config.jsonc" ]]; then
        cfg_src="$var_dir/config.jsonc"
    elif [[ -e "$theme_dir/config.jsonc" ]]; then
        cfg_src="$theme_dir/config.jsonc"
    else
        cfg_src="$def_dir/config.jsonc"
    fi

    if [[ -e "$var_dir/modules.jsonc" ]]; then
        mod_src="$var_dir/modules.jsonc"
    elif [[ -e "$theme_dir/modules.jsonc" ]]; then
        mod_src="$theme_dir/modules.jsonc"
    elif [[ -e "$def_dir/modules.jsonc" ]]; then
        mod_src="$def_dir/modules.jsonc"
    else
        mod_src="$mod_global"
    fi

    if [[ -e "$var_dir/style.css" ]]; then
        css_src="$var_dir/style.css"
    elif [[ -e "$var_dir/style-custom.css" ]]; then
        css_src="$var_dir/style-custom.css"
    elif [[ -e "$def_dir/style.css" ]]; then
        css_src="$def_dir/style.css"
    else
        css_src="$def_dir/style-custom.css"
    fi

    if [[ -e "$var_dir/colors.css" ]]; then
        col_src="$var_dir/colors.css"
    elif [[ -e "$theme_dir/colors.css" ]]; then
        col_src="$theme_dir/colors.css"
    else
        col_src="$col_global"
    fi

    # Link resolved config & modules naar current/
    [[ -n "$cfg_src" && -e "$cfg_src" ]] && ln -sfn "$cfg_src" "$cur/config.jsonc"
    [[ -n "$mod_src" && -e "$mod_src" ]] && ln -sfn "$mod_src" "$cur/modules.jsonc"

    # ---- colors.css: avoid loops & "same file" errors ----
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

    # Produce safe preprocessed CSS into current/style.resolved.css
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

    # Link top-level Waybar paths to the active theme output
    ln -sfn "$cur/config.jsonc"        "$cfg/config.jsonc"
    ln -sfn "$cur/modules.jsonc"       "$cfg/modules.jsonc"
    ln -sfn "$cur/style.resolved.css"  "$cfg/style.css"
    ln -sfn "$cur/colors.css"          "$cfg/colors.css"

    # Restart or soft-reload Waybar (exactly once)
    if systemctl --user is-enabled waybar.service >/dev/null 2>&1 \
       || systemctl --user is-active waybar.service >/dev/null 2>&1; then
        systemctl --user restart waybar.service || true
    else
        pkill -USR2 waybar 2>/dev/null || true
    fi

    notify "Waybar theme" "Applied: $theme"
=======
  local token
  if   [[ $# == 1 ]]; then token="$1"
  elif [[ $# == 2 ]]; then token="$1/$2"
  else echo "Usage: switch_theme THEME[/VARIANT] | THEME VARIANT" >&2; return 2; fi
  _ensure "$token" || return 1
  _apply_theme_files
  _reload_waybar()
  {
    _reload_waybar
  }
  _reload_waybar
  echo "Waybar theme: Applied: $token (target=$_target_base)"
>>>>>>> backtosystemd
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
      if [[ -z "$has_root" && $any_var -eq 0 ]]; then printf '%s/\n' "$fam"; fi
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
  if [[ $# -eq 0 ]]; then print_help; exit 2; fi
  case "${1:-}" in
    --help|-h)  print_help ;;
    --list)     list_themes ;;
    --apply)    shift; switch_theme "$@" ;;
    *)          switch_theme "$@" ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then main "$@"; fi

