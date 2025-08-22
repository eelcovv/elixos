#!/usr/bin/env bash
# waybar-switch-theme (link-tree v4.2: loader gebruikt @import "...")
set -euo pipefail

: "${WAYBAR_DIR:=$HOME/.config/waybar}"
: "${THEMES_DIR:=$WAYBAR_DIR/themes}"
: "${SERVICE:=waybar-managed.service}"
: "${DEBUG:=0}"

[ "$DEBUG" = "2" ] && set -x
log(){ [ "$DEBUG" = "1" ] && printf 'DEBUG: %s\n' "$*" >&2 || true; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if [ $# -eq 0 ]; then die "Usage: $(basename "$0") <family>[/<variant>] or <family> <variant>"; fi
if [ $# -ge 2 ]; then SEL="$1/$2"; else SEL="$1"; fi

family="${SEL%%/*}"
variant=""; [ "$SEL" != "$family" ] && variant="${SEL#*/}"

family_dir="$THEMES_DIR/$family"
[ -d "$family_dir" ] || die "Theme not found: $family ($family_dir)"
base_css="$family_dir/style.css"
[ -f "$base_css" ] || die "Missing base css: $base_css"

var_css=""
if [ -n "$variant" ]; then
  [ -d "$family_dir/$variant" ] || die "Variant not found: $family/$variant"
  [ -f "$family_dir/$variant/style.css" ] || die "Variant css missing: $family/$variant/style.css"
  var_css="$family_dir/$variant/style.css"
fi

mkdir -p "$WAYBAR_DIR"
[ -f "$WAYBAR_DIR/colors.css" ] || printf '/* colors */\n' >"$WAYBAR_DIR/colors.css"
[ -f "$WAYBAR_DIR/modules.jsonc" ] || printf '{}\n' >"$WAYBAR_DIR/modules.jsonc"
[ -f "$WAYBAR_DIR/waybar-quicklinks.json" ] || printf '[]\n' >"$WAYBAR_DIR/waybar-quicklinks.json"

current="$WAYBAR_DIR/current"
current_tmp="$WAYBAR_DIR/current.tmp"
rm -rf "$current_tmp" 2>/dev/null || true

install -d "$current_tmp"
if [ -d "$THEMES_DIR/assets" ]; then
  install -d "$current_tmp/themes"
  ln -sfn "$THEMES_DIR/assets" "$current_tmp/themes/assets"
fi

install -d "$current_tmp/$family"
ln -sfn "$THEMES_DIR"               "$current_tmp/$family/themes"
ln -sfn "$base_css"                  "$current_tmp/$family/style.css"
ln -sfn "$WAYBAR_DIR/colors.css"     "$current_tmp/$family/colors.css"

if [ -n "$variant" ]; then
  install -d "$current_tmp/$family/$variant"
  ln -sfn "$THEMES_DIR"               "$current_tmp/$family/$variant/themes"
  ln -sfn "$var_css"                  "$current_tmp/$family/$variant/style.css"
  ln -sfn "$WAYBAR_DIR/colors.css"    "$current_tmp/$family/$variant/colors.css"
fi

sel_cfg=""
if [ -n "$variant" ] && [ -f "$family_dir/$variant/config.jsonc" ]; then
  sel_cfg="$family_dir/$variant/config.jsonc"
elif [ -f "$family_dir/config.jsonc" ]; then
  sel_cfg="$family_dir/config.jsonc"
fi

rm -rf "$current"
mv -T "$current_tmp" "$current"

# Loader: gebruik @import "..." (zonder url())
if [ -n "$variant" ]; then
  printf '/* loader */\n@import "current/%s/%s/style.css";\n' "$family" "$variant" > "$WAYBAR_DIR/style.css"
else
  printf '/* loader */\n@import "current/%s/style.css";\n' "$family" > "$WAYBAR_DIR/style.css"
fi

if [ -n "$sel_cfg" ]; then
  ln -sfn "$sel_cfg" "$WAYBAR_DIR/config.jsonc"
else
  [ -f "$WAYBAR_DIR/config.jsonc" ] || printf '{}\n' >"$WAYBAR_DIR/config.jsonc"
fi
ln -sfn "$WAYBAR_DIR/config.jsonc" "$WAYBAR_DIR/config"

# Reload/start Waybar
if systemctl --user is-active --quiet "$SERVICE"; then
  systemctl --user reload-or-restart "$SERVICE" >/dev/null 2>&1 || true
else
  systemctl --user start "$SERVICE" >/dev/null 2>&1 || pkill -USR2 -x waybar >/dev/null 2>&1 || true
fi

printf 'Waybar theme: Applied: %s\n' "$SEL"

