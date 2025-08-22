#!/usr/bin/env bash
# waybar-switch-theme (link-tree variant)
# Simpel & robuust: maak onder ~/.config/waybar/current een symlink-boom
# die de themes-structuur spiegelt. Zet style.css/config.jsonc in ~/.config/waybar
# als symlink naar de gekozen variant/family. Imports als ../style.css blijven werken.
set -euo pipefail

: "${WAYBAR_DIR:=$HOME/.config/waybar}"
: "${THEMES_DIR:=$WAYBAR_DIR/themes}"
: "${SERVICE:=waybar-managed.service}"
: "${DEBUG:=0}"

log(){ [ "$DEBUG" = "1" ] && printf 'DEBUG: %s\n' "$*" >&2; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }

if [ $# -eq 0 ]; then
  die "Usage: $(basename "$0") <family>[ / <variant>]  |  <family> <variant>"
fi
if [ $# -ge 2 ]; then
  SEL="$1/$2"
else
  SEL="$1"
fi

family="${SEL%%/*}"
variant=""
[ "$SEL" != "$family" ] && variant="${SEL#*/}"

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

# 1) bouw link-tree onder ~/.config/waybar/current
current="$WAYBAR_DIR/current"
rm -rf "$current.tmp" 2>/dev/null || true
mkdir -p "$current.tmp/$family"

# assets → symlink naar themes/assets (zodat url('themes/assets/...') werkt)
if [ -d "$THEMES_DIR/assets" ]; then
  mkdir -p "$current.tmp/themes"
  ln -sfn "$THEMES_DIR/assets" "$current.tmp/themes/assets"
fi

# family/style.css → symlink naar echte base css
ln -sfn "$base_css" "$current.tmp/$family/style.css"

# variant subdir (optioneel)
if [ -n "$variant" ]; then
  mkdir -p "$current.tmp/$family/$variant"
  ln -sfn "$var_css" "$current.tmp/$family/$variant/style.css"
fi

# (optioneel) family/variant config.jsonc preferentie
sel_cfg=""
if [ -n "$variant" ] && [ -f "$family_dir/$variant/config.jsonc" ]; then
  sel_cfg="$family_dir/$variant/config.jsonc"
elif [ -f "$family_dir/config.jsonc" ]; then
  sel_cfg="$family_dir/config.jsonc"
fi

# 2) atomair wisselen van current → current.tmp
mv -T "$current.tmp" "$current"

# 3) style.css/config.jsonc in ~/.config/waybar als symlink naar de gekozen bron
if [ -n "$variant" ]; then
  # style.css → .../current/<family>/<variant>/style.css
  ln -sfn "$current/$family/$variant/style.css" "$WAYBAR_DIR/style.css"
else
  ln -sfn "$current/$family/style.css" "$WAYBAR_DIR/style.css"
fi

if [ -n "$sel_cfg" ]; then
  ln -sfn "$sel_cfg" "$WAYBAR_DIR/config.jsonc"
else
  # behoud bestaande config.jsonc als er geen theme-config is
  [ -f "$WAYBAR_DIR/config.jsonc" ] || printf '{}\n' >"$WAYBAR_DIR/config.jsonc"
fi

# compat symlink
ln -sfn "$WAYBAR_DIR/config.jsonc" "$WAYBAR_DIR/config"
[ -f "$WAYBAR_DIR/colors.css" ] || printf '/* colors */\n' >"$WAYBAR_DIR/colors.css"
[ -f "$WAYBAR_DIR/modules.jsonc" ] || printf '{}\n' >"$WAYBAR_DIR/modules.jsonc"

# 4) reload waybar
if systemctl --user is-active --quiet "$SERVICE"; then
  systemctl --user reload-or-restart "$SERVICE" >/dev/null 2>&1 || true
else
  pkill -USR2 -x waybar >/dev/null 2>&1 || true
fi

printf 'Waybar theme: Applied: %s\n' "$SEL"

