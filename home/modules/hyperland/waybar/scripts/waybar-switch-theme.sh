#!/usr/bin/env bash
# Switch Waybar theme (family or family/variant). Robust and DEBUG-safe.
set -euo pipefail

# ---- Settings ----------------------------------------------------------------
: "${WAYBAR_THEMES_DIR:=$HOME/.config/waybar/themes}"
: "${WAYBAR_CFG_DIR:=$HOME/.config/waybar}"
: "${WAYBAR_BIN:=waybar}"
: "${WAYBAR_SERVICE:=waybar-managed.service}"
: "${WAYBAR_THEME_DEBUG:=0}"   # 1 = print debug lines

# ---- Helpers -----------------------------------------------------------------
dbg() { [ "$WAYBAR_THEME_DEBUG" = "1" ] && printf 'DEBUG: %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

abs() { # resolve to absolute path (best-effort)
  case "$1" in /*) printf '%s\n' "$1" ;; *) printf '%s/%s\n' "$(pwd)" "$1" ;; esac
}

is_running() { pgrep -x waybar >/dev/null 2>&1; }

reload_waybar() {
  # Try soft reload first; if not running, start; if still dead, restart.
  if is_running; then
    pkill -USR2 -x waybar || true
    sleep 0.15
    return 0
  fi
  systemctl --user start "$WAYBAR_SERVICE" >/dev/null 2>&1 || true
  sleep 0.25
  is_running || systemctl --user restart "$WAYBAR_SERVICE" >/dev/null 2>&1 || true
}

ensure_seed_files() {
  mkdir -p "$WAYBAR_CFG_DIR"
  [ -f "$WAYBAR_CFG_DIR/config.jsonc" ] || {
    [ -f "$WAYBAR_THEMES_DIR/default/config.jsonc" ] \
      && cp -f "$WAYBAR_THEMES_DIR/default/config.jsonc" "$WAYBAR_CFG_DIR/config.jsonc" \
      || printf '{}\n' >"$WAYBAR_CFG_DIR/config.jsonc"
  }
  [ -f "$WAYBAR_CFG_DIR/style.css" ] || {
    [ -f "$WAYBAR_THEMES_DIR/default/style.css" ] \
      && cp -f "$WAYBAR_THEMES_DIR/default/style.css" "$WAYBAR_CFG_DIR/style.css" \
      || printf '/* default */\n' >"$WAYBAR_CFG_DIR/style.css"
  }
  [ -f "$WAYBAR_CFG_DIR/colors.css" ] || printf '/* default colors */\n' >"$WAYBAR_CFG_DIR/colors.css"
  ln -sfn "$WAYBAR_CFG_DIR/config.jsonc" "$WAYBAR_CFG_DIR/config"
}

compose_css() {
  # args: <variant_css_or_empty> <base_css> -> stdout
  local variant="$1" base="$2"
  if [ -n "$variant" ] && [ -f "$variant" ]; then
    cat "$variant" "$base"
  else
    cat "$base"
  fi
}

normalize_css() {
  # stdin css -> stdout normalized css
  # - drop @import of colors.css (we manage colors.css separately)
  # - rewrite ../assets → absolute assets dir
  local assets_dir="$WAYBAR_THEMES_DIR/assets"
  sed -E '/@import[[:space:]]+("?'\''?)\.?\/?colors\.css\1;[[:space:]]*$/d' \
  | sed -E "s,url\((['\"]?)\.\.\/assets\/,url(\1$(printf '%s' "$assets_dir" | sed 's/[.[\*^$()+?{}|]/\\&/g')\/,g"
}

write_atomic() {
  # args: <dest_path> ; reads content from stdin and writes atomically
  local dest="$1" tmp
  tmp="$(mktemp "${dest}.tmp.XXXX")"
  cat >"$tmp"
  mv -f "$tmp" "$dest"
}

resolve_theme_paths() {
  # args: <sel> -> echo base_css variant_css
  local sel="$1" base_dir var_dir base_css variant_css
  case "$sel" in
    */*)
      base_dir="$WAYBAR_THEMES_DIR/${sel%%/*}"
      var_dir="$WAYBAR_THEMES_DIR/$sel"
      ;;
    *)
      base_dir="$WAYBAR_THEMES_DIR/$sel"
      var_dir=""
      ;;
  esac
  base_css="$base_dir/style.css"
  variant_css=""
  [ -n "$var_dir" ] && variant_css="$var_dir/style.css"
  [ -f "$base_css" ] || die "Base style missing: $base_css"
  if [ -n "$variant_css" ] && [ ! -f "$variant_css" ]; then
    dbg "Variant style not found at $variant_css, proceeding with base only"
    variant_css=""
  fi
  printf '%s %s\n' "$base_css" "$variant_css"
}

# ---- Parse input -------------------------------------------------------------
sel="${1:-}"
if [ -z "$sel" ]; then
  die "Usage: $(basename "$0") <family>[/<variant>]"
fi

ensure_seed_files

# ---- Resolve files -----------------------------------------------------------
read -r base_css variant_css < <(resolve_theme_paths "$sel")
dbg "base_css=$base_css"
[ -n "$variant_css" ] && dbg "variant_css=$variant_css"

# ---- Copy config.jsonc from family root if exists ----------------------------
# Keep user's local config if none in theme.
family="${sel%%/*}"
theme_cfg="$WAYBAR_THEMES_DIR/$family/config.jsonc"
if [ -f "$theme_cfg" ]; then
  dbg "copying base config $theme_cfg → $WAYBAR_CFG_DIR/config.jsonc"
  cp -f "$theme_cfg" "$WAYBAR_CFG_DIR/config.jsonc"
else
  dbg "no theme config for $family, leaving existing config.jsonc"
fi

# ---- Compose & normalize CSS, then write atomically --------------------------
dbg "compose css"
compose_css "$variant_css" "$base_css" \
  | normalize_css \
  | write_atomic "$WAYBAR_CFG_DIR/style.css"

# Ensure quicklinks placeholder exists (some configs include it)
[ -f "$WAYBAR_CFG_DIR/waybar-quicklinks.json" ] || printf '[]\n' >"$WAYBAR_CFG_DIR/waybar-quicklinks.json"

# ---- Reload Waybar -----------------------------------------------------------
dbg "reload waybar"
reload_waybar

printf 'Waybar theme: Applied: %s\n' "$sel"

