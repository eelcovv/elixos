#!/usr/bin/env bash
# Waybar theme switcher — direct write (no "current", no symlinks)
# Accepts: waybar-switch-theme <theme> [variant] | <theme/variant>

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <theme> [variant] | <theme/variant>" >&2
  exit 2
}

# ---------- parse args ----------
theme=""; variant=""
case "$#" in
  1) if [[ "$1" == */* ]]; then theme="${1%%/*}"; variant="${1#*/}"; else theme="$1"; fi ;;
  2) theme="$1"; variant="$2" ;;
  *) usage ;;
esac
[[ -n "$theme" ]] || usage
combo="${theme}${variant:+/$variant}"

# ---------- paths ----------
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
THEME_DIR="$THEMES/$theme"
VAR_DIR="$THEME_DIR/${variant:-}"

log()   { printf '%s\n' "$*"; }
die()   { echo "ERROR: $*" >&2; exit 1; }

[[ -d "$THEME_DIR" ]] || die "Theme not found: $THEME_DIR"
if [[ -n "$variant" && ! -d "$VAR_DIR" ]]; then
  die "Variant not found: $VAR_DIR"
fi

mkdir -p "$CFG"

# ---------- helpers ----------
safe_copy_if_exists() {
  local src="$1" dest="$2"
  [[ -f "$src" ]] || return 1
  install -Dm0644 -- "$src" "$dest"
}

replace_symlink_with_file_if_needed() {
  local dest="$1" fallback="${2:-}"
  if [[ -L "$dest" ]]; then
    local src_real; src_real="$(readlink -f -- "$dest" || true)"
    rm -f -- "$dest"
    if [[ -n "$src_real" && -f "$src_real" ]]; then
      install -Dm0644 -- "$src_real" "$dest"
    elif [[ -n "$fallback" ]]; then
      printf '%s\n' "$fallback" >"$dest"; chmod 0644 "$dest"
    else
      : >"$dest"; chmod 0644 "$dest"
    fi
  fi
}

ensure_includes_exist() {
  local cfg_json="$1"
  [[ -f "$cfg_json" ]] || return 0
  mapfile -t includes < <(awk '
    /"include"[[:space:]]*:/,/\]/ {
      while (match($0, /"~\/\.config\/[^"]+\.json[c]?"/)) {
        print substr($0, RSTART+1, RLENGTH-2)
        $0 = substr($0, RSTART+RLENGTH)
      }
    }' "$cfg_json")
  for inc in "${includes[@]}"; do
    local abspath="${inc/#\~/$HOME}"
    mkdir -p "$(dirname -- "$abspath")"
    [[ -e "$abspath" ]] && continue
    case "$abspath" in
      */waybar-quicklinks.json) printf '[]\n'  >"$abspath" ;;
      *)                        printf '{}\n'  >"$abspath" ;;
    esac
    chmod 0644 "$abspath"
  done
}

reload_waybar() {
  if systemctl --user is-active --quiet waybar-managed.service; then
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
  else
    pkill -USR2 -x waybar 2>/dev/null || true
  fi
}

# ---------- 1) base copies ----------
safe_copy_if_exists "$THEME_DIR/config.jsonc" "$CFG/config.jsonc" || true
safe_copy_if_exists "$THEME_DIR/style.css"    "$CFG/style.css"    || true
safe_copy_if_exists "$THEME_DIR/modules.jsonc" "$CFG/modules.jsonc" || true

# ---------- 2) overlay variant ----------
if [[ -n "$variant" ]]; then
  safe_copy_if_exists "$VAR_DIR/config.jsonc" "$CFG/config.jsonc" || true
  safe_copy_if_exists "$VAR_DIR/style.css"    "$CFG/style.css"    || true
  safe_copy_if_exists "$VAR_DIR/modules.jsonc" "$CFG/modules.jsonc" || true
fi

# ---------- 3) colors.css from global ----------
replace_symlink_with_file_if_needed "$CFG/colors.css" '/* default colors (placeholder) */'
if [[ ! -s "$CFG/colors.css" ]]; then
  printf '/* default colors */\n' >"$CFG/colors.css"
  chmod 0644 "$CFG/colors.css"
fi

# ---------- 4) minimum fallbacks ----------
if [[ ! -f "$CFG/config.jsonc" ]]; then
  printf '{ "layer":"top", "position":"top", "height":32, "modules-center":["clock"], "clock":{"format":"{:%H:%M}"} }\n' >"$CFG/config.jsonc"
  chmod 0644 "$CFG/config.jsonc"
fi
if [[ ! -f "$CFG/style.css" ]]; then
  printf '@import url("colors.css");\nwindow#waybar { background: #202020; }\n* { color: #d0d0d0; font-size: 12px; }\n' >"$CFG/style.css"
  chmod 0644 "$CFG/style.css"
fi
if [[ ! -f "$CFG/modules.jsonc" ]]; then
  printf '{}\n' >"$CFG/modules.jsonc"
  chmod 0644 "$CFG/modules.jsonc"
fi

# ---------- 5) includes placeholders ----------
ensure_includes_exist "$CFG/config.jsonc"

# ---------- 6) reload ----------
reload_waybar
log "Waybar theme: Applied: $combo"

