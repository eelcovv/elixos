#!/usr/bin/env bash
# Waybar theme switcher — direct write (no "current", no symlinks)
# Usage: waybar-switch-theme <theme> [variant] | <theme/variant>
#
# Supports debug logging via: WAYBAR_THEME_DEBUG=1 waybar-switch-theme ml4w-blur light

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <theme> [variant] | <theme/variant>" >&2
  exit 2
}

# ---------- argument parsing ----------
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
dbg()   { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2; }
die()   { echo "ERROR: $*" >&2; exit 1; }

[[ -d "$THEME_DIR" ]] || die "Theme not found: $THEME_DIR"
if [[ -n "$variant" && ! -d "$VAR_DIR" ]]; then
  die "Variant not found: $VAR_DIR"
fi

mkdir -p "$CFG"

# ---------- helpers ----------
safe_copy_if_exists() {
  local src="$1" dest="$2" label="$3"
  if [[ -f "$src" ]]; then
    dbg "copying $label $src → $dest"
    install -Dm0644 -- "$src" "$dest"
    return 0
  fi
  return 1
}

replace_symlink_with_file_if_needed() {
  local dest="$1" fallback="${2:-}"
  if [[ -L "$dest" ]]; then
    local src_real; src_real="$(readlink -f -- "$dest" || true)"
    dbg "replacing symlink $dest (→ $src_real)"
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
  # Ensures that any "include" paths in config.jsonc exist as placeholder files
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
    dbg "created include placeholder: $abspath"
  done
}

merge_styles() {
  # Merge style.css: variant first (defines variables), then base theme
  local out="$1"
  local tmp="$(mktemp)"
  >"$tmp"
  if [[ -n "$variant" && -f "$VAR_DIR/style.css" ]]; then
    dbg "adding variant style.css from $VAR_DIR"
    cat "$VAR_DIR/style.css" >>"$tmp"
    echo "" >>"$tmp"
  fi
  if [[ -f "$THEME_DIR/style.css" ]]; then
    dbg "adding theme style.css from $THEME_DIR"
    cat "$THEME_DIR/style.css" >>"$tmp"
  fi
  install -Dm0644 -- "$tmp" "$out"
  rm -f "$tmp"
}

reload_waybar() {
  if systemctl --user is-active --quiet waybar-managed.service; then
    dbg "reloading waybar via systemd"
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
  else
    dbg "sending USR2 to waybar process"
    pkill -USR2 -x waybar 2>/dev/null || true
  fi
}

# ---------- 1) copy config + modules ----------
if [[ -n "$variant" ]]; then
  safe_copy_if_exists "$VAR_DIR/config.jsonc" "$CFG/config.jsonc" "variant" || true
  safe_copy_if_exists "$VAR_DIR/modules.jsonc" "$CFG/modules.jsonc" "variant" || true
fi
safe_copy_if_exists "$THEME_DIR/config.jsonc" "$CFG/config.jsonc" "theme" || true
safe_copy_if_exists "$THEME_DIR/modules.jsonc" "$CFG/modules.jsonc" "theme" || true

# ---------- 2) merge style ----------
merge_styles "$CFG/style.css"

# ---------- 3) handle colors.css ----------
replace_symlink_with_file_if_needed "$CFG/colors.css" '/* default colors (placeholder) */'
if [[ ! -s "$CFG/colors.css" ]]; then
  printf '/* default colors */\n' >"$CFG/colors.css"
  chmod 0644 "$CFG/colors.css"
fi

# ---------- 4) minimal fallbacks ----------
if [[ ! -f "$CFG/config.jsonc" ]]; then
  dbg "writing fallback config.jsonc"
  printf '{ "layer":"top", "position":"top", "height":32, "modules-center":["clock"], "clock":{"format":"{:%H:%M}"} }\n' >"$CFG/config.jsonc"
  chmod 0644 "$CFG/config.jsonc"
fi
if [[ ! -f "$CFG/style.css" ]]; then
  dbg "writing fallback style.css"
  printf '@import url("colors.css");\nwindow#waybar { background: #202020; }\n* { color: #d0d0d0; font-size: 12px; }\n' >"$CFG/style.css"
  chmod 0644 "$CFG/style.css"
fi
if [[ ! -f "$CFG/modules.jsonc" ]]; then
  dbg "writing fallback modules.jsonc"
  printf '{}\n' >"$CFG/modules.jsonc"
  chmod 0644 "$CFG/modules.jsonc"
fi

# ---------- 5) includes ----------
ensure_includes_exist "$CFG/config.jsonc"

# ---------- 6) reload ----------
reload_waybar
log "Waybar theme: Applied: $combo"

