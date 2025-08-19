#!/usr/bin/env bash
# Waybar theme switcher — direct write (no "current", no symlinks)
# - Accepts:  waybar-switch-theme <theme> [variant]
#             waybar-switch-theme <theme>/<variant>
# - Copies ONLY config.jsonc and style.css from the theme into ~/.config/waybar/
# - If a variant exists, overlay its config.jsonc/style.css on top (overwrite)
# - colors.css comes from the global ~/.config/waybar/colors.css (not from theme)
# - Ensures missing include JSON files under ~/.config/... exist as placeholders
# - Reloads Waybar via systemd (waybar-managed) or SIGUSR2
#
# NOTE: This intentionally avoids "current" directories and symlinks.

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <theme> [variant] | <theme/variant>" >&2
  exit 2
}

# ---------- parse args --------------------------------------------------------
theme=""; variant=""
case "$#" in
  1) if [[ "$1" == */* ]]; then theme="${1%%/*}"; variant="${1#*/}"; else theme="$1"; fi ;;
  2) theme="$1"; variant="$2" ;;
  *) usage ;;
esac
[[ -n "$theme" ]] || usage
combo="${theme}${variant:+/$variant}"

# ---------- paths -------------------------------------------------------------
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
THEME_DIR="$THEMES/$theme"
VAR_DIR="$THEME_DIR/${variant:-}"

log()   { printf '%s\n' "$*"; }
debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }
die()   { echo "ERROR: $*" >&2; exit 1; }

# ---------- sanity ------------------------------------------------------------
[[ -d "$THEME_DIR" ]] || die "Theme not found: $THEME_DIR"
if [[ -n "$variant" && ! -d "$VAR_DIR" ]]; then
  die "Variant not found: $VAR_DIR"
fi

mkdir -p "$CFG"

# ---------- helpers -----------------------------------------------------------
safe_copy_if_exists() {
  # safe_copy_if_exists SRC DEST
  local src="$1" dest="$2"
  if [[ -f "$src" ]]; then
    install -Dm0644 -- "$src" "$dest"
    return 0
  fi
  return 1
}

replace_symlink_with_file_if_needed() {
  # replace_symlink_with_file_if_needed TARGET [fallback_content]
  local dest="$1" fallback="${2:-}"
  if [[ -L "$dest" ]]; then
    # If it's a symlink, dereference then copy into a regular file
    local src_real
    src_real="$(readlink -f -- "$dest" || true)"
    rm -f -- "$dest"
    if [[ -n "$src_real" && -f "$src_real" ]]; then
      install -Dm0644 -- "$src_real" "$dest"
    elif [[ -n "$fallback" ]]; then
      printf '%s\n' "$fallback" >"$dest"
      chmod 0644 "$dest"
    else
      : >"$dest"
      chmod 0644 "$dest"
    fi
  fi
}

ensure_includes_exist() {
  # ensure_includes_exist CONFIG_JSONC
  local cfg_json="$1"
  [[ -f "$cfg_json" ]] || return 0

  # Parse "~/.config/...json[c]?" includes in a very tolerant way
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

reload_waybar() {
  if systemctl --user is-active --quiet waybar-managed.service; then
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
  else
    pkill -USR2 -x waybar 2>/dev/null || true
  fi
}

# ---------- 1) copy base files -----------------------------------------------
# We write directly to ~/.config/waybar/, no "current" dir and no symlinks.

# Base theme files (only these two are authoritative)
copied_any=0
safe_copy_if_exists "$THEME_DIR/config.jsonc" "$CFG/config.jsonc" && copied_any=1
safe_copy_if_exists "$THEME_DIR/style.css"    "$CFG/style.css"    && copied_any=1

# Optional: if a theme ships modules.jsonc alongside config, bring it too
safe_copy_if_exists "$THEME_DIR/modules.jsonc" "$CFG/modules.jsonc" || true

# ---------- 2) overlay variant files (if present) ----------------------------
if [[ -n "$variant" ]]; then
  safe_copy_if_exists "$VAR_DIR/config.jsonc" "$CFG/config.jsonc" || true
  safe_copy_if_exists "$VAR_DIR/style.css"    "$CFG/style.css"    || true
  safe_copy_if_exists "$VAR_DIR/modules.jsonc" "$CFG/modules.jsonc" || true
fi

# ---------- 3) ensure colors.css comes from global location ------------------
# You said: colors.css should *not* come from the theme; it lives in waybar/colors.css.
# Ensure it exists as a regular file (never a dangling symlink from earlier setups).
replace_symlink_with_file_if_needed "$CFG/colors.css" '/* default colors (placeholder) */'
if [[ ! -f "$CFG/colors.css" || ! -s "$CFG/colors.css" ]]; then
  # If Home Manager published a default colors.css via xdg.configFile, it is already here.
  # Otherwise create a small neutral default.
  printf '/* default colors */\n' >"$CFG/colors.css"
  chmod 0644 "$CFG/colors.css"
fi

# ---------- 4) ensure minimal defaults if a theme was sparse -----------------
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

# ---------- 5) (optional) includes robustness --------------------------------
ensure_includes_exist "$CFG/config.jsonc"

# ---------- 6) reload waybar --------------------------------------------------
reload_waybar
log "Waybar theme: Applied: $combo"

