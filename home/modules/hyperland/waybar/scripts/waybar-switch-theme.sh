#!/usr/bin/env bash
# Switch Waybar theme (family or family/variant). Robust and DEBUG-safe.
set -euo pipefail

: "${WAYBAR_THEMES_DIR:=$HOME/.config/waybar/themes}"
: "${WAYBAR_CFG_DIR:=$HOME/.config/waybar}"
: "${WAYBAR_SERVICE:=waybar-managed.service}"
: "${WAYBAR_THEME_DEBUG:=0}"

dbg() { [ "$WAYBAR_THEME_DEBUG" = "1" ] && printf 'DEBUG: %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
is_running() { pgrep -x waybar >/dev/null 2>&1; }

# Accept "family/variant" or "family variant"
if [ $# -eq 0 ]; then
  die "Usage: $(basename "$0") <family>[/<variant>] or <family> <variant>"
fi
if [ $# -ge 2 ]; then
  sel="$1/$2"
else
  sel="$1"
fi

ensure_seed_files() {
  mkdir -p "$WAYBAR_CFG_DIR"
  [ -f "$WAYBAR_CFG_DIR/config.jsonc" ] || printf '{}\n' >"$WAYBAR_CFG_DIR/config.jsonc"
  [ -f "$WAYBAR_CFG_DIR/style.css" ]   || printf '/* default */\n' >"$WAYBAR_CFG_DIR/style.css"
  [ -f "$WAYBAR_CFG_DIR/colors.css" ]  || printf '/* default colors */\n' >"$WAYBAR_CFG_DIR/colors.css"
  ln -sfn "$WAYBAR_CFG_DIR/config.jsonc" "$WAYBAR_CFG_DIR/config"
  [ -f "$WAYBAR_CFG_DIR/waybar-quicklinks.json" ] || printf '[]\n' >"$WAYBAR_CFG_DIR/waybar-quicklinks.json"
}

reload_waybar() {
  if is_running; then
    pkill -USR2 -x waybar || true
    sleep 0.15
    return 0
  fi
  systemctl --user start "$WAYBAR_SERVICE" >/dev/null 2>&1 || true
  sleep 0.25
  is_running || systemctl --user restart "$WAYBAR_SERVICE" >/dev/null 2>&1 || true
}

write_atomic() {
  local dest="$1" tmp; tmp="$(mktemp "${dest}.tmp.XXXX")"
  cat >"$tmp" && mv -f "$tmp" "$dest"
}

# Resolve paths
family="${sel%%/*}"
variant="" ; [ "$sel" != "$family" ] && variant="${sel#*/}"

base_dir="$WAYBAR_THEMES_DIR/$family"
var_dir="$WAYBAR_THEMES_DIR/$family/$variant"

base_css="$base_dir/style.css"
[ -f "$base_css" ] || die "Base style missing: $base_css"

variant_css=""
if [ -n "$variant" ] && [ -f "$var_dir/style.css" ]; then
  variant_css="$var_dir/style.css"
fi

dbg "base_css=$base_css"
[ -n "$variant_css" ] && dbg "variant_css=$variant_css" || dbg "no variant css"

# Copy config.jsonc from family root if present
if [ -f "$base_dir/config.jsonc" ]; then
  dbg "copying base config $base_dir/config.jsonc → $WAYBAR_CFG_DIR/config.jsonc"
  cp -f "$base_dir/config.jsonc" "$WAYBAR_CFG_DIR/config.jsonc"
fi

# Compose CSS: (variant-without-import) + base
compose_css() {
  # strip any import of ../style.css or ./style.css or "style.css"
  strip_imports() {
    sed -E '/@import[[:space:]]+url?\((["'\'']?)\.\.\/?style\.css\1\)[[:space:]]*;[[:space:]]*$/d;
             /@import[[:space:]]+url?\((["'\'']?)\.?\/?style\.css\1\)[[:space:]]*;[[:space:]]*$/d' \
    | sed -E '/@import[[:space:]]+["'\'']\.\.\/?style\.css["'\''][[:space:]]*;[[:space:]]*$/d;
              /@import[[:space:]]+["'\'']\.?\/?style\.css["'\''][[:space:]]*;[[:space:]]*$/d'
  }
  if [ -n "$variant_css" ]; then
    strip_imports <"$variant_css"
  fi
  cat "$base_css"
}

# Normalize: drop colors import; rewrite ../assets → absolute
normalize_css() {
  local assets_dir="$WAYBAR_THEMES_DIR/assets"
  sed -E '/@import[[:space:]]+("'\''?)\.?\/?colors\.css\1;[[:space:]]*$/d' \
  | sed -E "s,url\((['\"]?)\.\.\/assets\/,url(\1$(printf '%s' "$assets_dir" | sed 's/[.[\*^$()+?{}|]/\\&/g')\/,g"
}

ensure_seed_files
dbg "compose css"
compose_css | normalize_css | write_atomic "$WAYBAR_CFG_DIR/style.css"

dbg "reload waybar"
reload_waybar

printf 'Waybar theme: Applied: %s\n' "$sel"

