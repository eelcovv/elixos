#!/usr/bin/env bash
# Waybar theme helper — direct write (no "current", no symlinks)
# This file defines functions so other scripts can `source` it and call `switch_theme`.
# It writes directly into ~/.config/waybar/{config.jsonc, style.css, modules.jsonc?}
# Colors are managed separately by Matugen and must live at ~/.config/waybar/colors.css.

set -euo pipefail

# --- Paths --------------------------------------------------------------------
WAYBAR_DIR="${WAYBAR_DIR:-$HOME/.config/waybar}"                   # -> ~/.config/waybar
WAYBAR_THEMES_DIR="${WAYBAR_THEMES_DIR:-$WAYBAR_DIR/themes}"       # -> ~/.config/waybar/themes
DEFAULT_FAMILY="${DEFAULT_FAMILY:-default}"

_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2; }

# --- Utilities ----------------------------------------------------------------
_die() { echo "ERROR: $*" >&2; exit 1; }

_copy_if_exists() {               # _copy_if_exists SRC DEST
  local src="$1" dest="$2"
  [[ -f "$src" ]] || return 1
  install -Dm0644 -- "$src" "$dest"
}

_replace_symlink_with_file() {    # _replace_symlink_with_file DEST [fallback]
  local dest="$1" fallback="${2:-}"
  if [[ -L "$dest" ]]; then
    local src_real; src_real="$(readlink -f -- "$dest" || true)"
    rm -f -- "$dest"
    if [[ -n "$src_real" && -f "$src_real" ]]; then
      install -Dm0644 -- "$src_real" "$dest"
    elif [[ -n "$fallback" ]]; then
      printf '%s\n' "$fallback" >"$dest"
      chmod 0644 "$dest"
    else
      : >"$dest"; chmod 0644 "$dest"
    fi
  fi
}

_ensure_includes_exist() {        # _ensure_includes_exist CONFIG_JSONC
  local cfg_json="$1"
  [[ -f "$cfg_json" ]] || return 0
  # Parse "~/.config/...json[c]?" entries inside an "include" array (lenient)
  mapfile -t includes < <(awk '
    /"include"[[:space:]]*:/,/\]/ {
      while (match($0, /"~\/\.config\/[^"]+\.json[c]?"/)) {
        print substr($0, RSTART+1, RLENGTH-2)
        $0 = substr($0, RSTART+RLENGTH)
      }
    }' "$cfg_json")
  for inc in "${includes[@]}"; do
    local abspath="${inc/#\~/$HOME}"
    local d; d="$(dirname -- "$abspath")"
    mkdir -p "$d"
    if [[ ! -e "$abspath" ]]; then
      case "$abspath" in
        */waybar-quicklinks.json) printf '[]\n' >"$abspath" ;;  # common ML4W include
        *)                        printf '{}\n' >"$abspath" ;;
      esac
      chmod 0644 "$abspath"
    fi
  done
}

_reload_waybar() {
  if systemctl --user is-active --quiet waybar-managed.service; then
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
  else
    pkill -USR2 -x waybar 2>/dev/null || true
  fi
}

# --- Public API ---------------------------------------------------------------
# switch_theme THEME[/VARIANT] | THEME VARIANT
switch_theme() {
  local token theme variant=""
  if   [[ $# == 1 ]]; then
    token="$1"
    if [[ "$token" == */* ]]; then theme="${token%%/*}"; variant="${token#*/}"; else theme="$token"; fi
  elif [[ $# == 2 ]]; then
    theme="$1"; variant="$2"
  else
    echo "Usage: switch_theme THEME[/VARIANT] | THEME VARIANT" >&2
    return 2
  fi

  local THEME_DIR="$WAYBAR_THEMES_DIR/$theme"
  local VAR_DIR="$THEME_DIR/${variant:-}"
  [[ -d "$THEME_DIR" ]] || _die "Theme not found: $THEME_DIR"
  if [[ -n "$variant" && ! -d "$VAR_DIR" ]]; then
    _die "Variant not found: $VAR_DIR"
  fi

  mkdir -p "$WAYBAR_DIR"

  # 1) base copies (only the authoritative two; modules.jsonc optional)
  local copied_any=0
  _copy_if_exists "$THEME_DIR/config.jsonc" "$WAYBAR_DIR/config.jsonc" && copied_any=1
  _copy_if_exists "$THEME_DIR/style.css"    "$WAYBAR_DIR/style.css"    && copied_any=1
  _copy_if_exists "$THEME_DIR/modules.jsonc" "$WAYBAR_DIR/modules.jsonc" || true

  # 2) overlay variant (overwrite if present)
  if [[ -n "$variant" ]]; then
    _copy_if_exists "$VAR_DIR/config.jsonc" "$WAYBAR_DIR/config.jsonc" || true
    _copy_if_exists "$VAR_DIR/style.css"    "$WAYBAR_DIR/style.css"    || true
    _copy_if_exists "$VAR_DIR/modules.jsonc" "$WAYBAR_DIR/modules.jsonc" || true
  fi

  # 3) ensure colors.css is local (Matugen-owned), never a dangling symlink
  _replace_symlink_with_file "$WAYBAR_DIR/colors.css" '/* default colors (placeholder) */'
  if [[ ! -s "$WAYBAR_DIR/colors.css" ]]; then
    printf '/* default colors */\n' >"$WAYBAR_DIR/colors.css"
    chmod 0644 "$WAYBAR_DIR/colors.css"
  fi

  # 4) minimal fallbacks if theme was sparse
  if [[ ! -f "$WAYBAR_DIR/config.jsonc" ]]; then
    printf '{ "layer":"top", "position":"top", "height":32, "modules-center":["clock"], "clock":{"format":"{:%H:%M}"} }\n' >"$WAYBAR_DIR/config.jsonc"
    chmod 0644 "$WAYBAR_DIR/config.jsonc"
  fi
  if [[ ! -f "$WAYBAR_DIR/style.css" ]]; then
    printf '@import url("colors.css");\nwindow#waybar { background: #202020; }\n* { color: #d0d0d0; font-size: 12px; }\n' >"$WAYBAR_DIR/style.css"
    chmod 0644 "$WAYBAR_DIR/style.css"
  fi
  if [[ ! -f "$WAYBAR_DIR/modules.jsonc" ]]; then
    printf '{}\n' >"$WAYBAR_DIR/modules.jsonc"
    chmod 0644 "$WAYBAR_DIR/modules.jsonc"
  fi

  # 5) be tolerant with includes
  _ensure_includes_exist "$WAYBAR_DIR/config.jsonc"

  # 6) reload and message
  _reload_waybar
  echo "Waybar theme: Applied: ${theme}${variant:+/$variant}"
}

list_themes() {
  local base="$WAYBAR_THEMES_DIR"
  local fam vdir
  while IFS= read -r -d '' famdir; do
    fam="$(basename "$famdir")"
    [[ "$fam" == .* ]] && continue
    [[ "$fam" == assets ]] && continue
    local root_has=""
    [[ -f "$famdir/style.css" || -f "$famdir/style-custom.css" ]] && root_has=1
    local any_var=0
    while IFS= read -r -d '' vdir; do
      [[ -f "$vdir/style.css" || -f "$vdir/style-custom.css" ]] || continue
      if [[ -z "$root_has" && $any_var -eq 0 ]]; then printf '%s/\n' "$fam"; fi
      printf '%s/%s\n' "$fam" "$(basename "$vdir")"
      any_var=1
    done < <(find -L "$famdir" -mindepth 1 -maxdepth 1 -type d -print0)
    [[ -n "$root_has" ]] && printf '%s\n' "$fam"
  done < <(find -L "$base" -mindepth 1 -maxdepth 1 -type d -print0)
}

