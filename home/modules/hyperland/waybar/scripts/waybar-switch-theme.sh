#!/usr/bin/env bash
# waybar-switch-theme (link-tree v3: symlink-boom + loader + colors.css links)
# Usage: waybar-switch-theme <family>[/<variant>] | <family> <variant>
set -euo pipefail

: "${WAYBAR_DIR:=$HOME/.config/waybar}"
: "${THEMES_DIR:=$WAYBAR_DIR/themes}"
: "${SERVICE:=waybar-managed.service}"
: "${DEBUG:=0}"

log(){ [ "$DEBUG" = "1" ] && printf 'DEBUG: %s\n' "$*" >&2; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# ---- args ----
if [ $# -eq 0 ]; then
  die "Usage: $(basename "$0") <family>[/<variant>] or <family> <variant>"
fi
if [ $# -ge 2 ]; then SEL="$1/$2"; else SEL="$1"; fi
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

# Ensure shared files exist in root (used as import target)
[ -f "$WAYBAR_DIR/colors.css" ] || printf '/* colors */\n' >"$WAYBAR_DIR/colors.css"
[ -f "$WAYBAR_DIR/modules.jsonc" ] || printf '{}\n' >"$WAYBAR_DIR/modules.jsonc"
[ -f "$WAYBAR_DIR/waybar-quicklinks.json" ] || printf '[]\n' >"$WAYBAR_DIR/waybar-quicklinks.json"

# ---- build link-tree under ~/.config/waybar/current ----
current="$WAYBAR_DIR/current"
rm -rf "$current.tmp" 2>/dev/null || true
mkdir -p "$current.tmp/$family"

# atomair vervangen
rm -rf "$current"
mv -T "$current.tmp" "$current"


# assets → symlink, zodat url("themes/assets/...") werkt
if [ -d "$THEMES_DIR/assets" ]; then
  mkdir -p "$current.tmp/themes"
  ln -sfn "$THEMES_DIR/assets" "$current.tmp/themes/assets"
fi

# family/style.css → base css
ln -sfn "$base_css" "$current.tmp/$family/style.css"
# family/colors.css → link naar root colors.css (voor @import "colors.css" in base)
ln -sfn "$WAYBAR_DIR/colors.css" "$current.tmp/$family/colors.css"

# variant/style.css (+ colors.css link) (optioneel)
if [ -n "$variant" ]; then
  mkdir -p "$current.tmp/$family/$variant"
  ln -sfn "$var_css" "$current.tmp/$family/$variant/style.css"
  ln -sfn "$WAYBAR_DIR/colors.css" "$current.tmp/$family/$variant/colors.css"
fi

# (opt) config.jsonc voorkeur: variant → family
sel_cfg=""
if [ -n "$variant" ] && [ -f "$family_dir/$variant/config.jsonc" ]; then
  sel_cfg="$family_dir/$variant/config.jsonc"
elif [ -f "$family_dir/config.jsonc" ]; then
  sel_cfg="$family_dir/config.jsonc"
fi

# atomair vervangen
mv -T "$current.tmp" "$current"

# ---- write loader style.css + config symlink ----
if [ -n "$variant" ]; then
  printf '/* loader */\n@import url("current/%s/%s/style.css");\n' "$family" "$variant" > "$WAYBAR_DIR/style.css"
else
  printf '/* loader */\n@import url("current/%s/style.css");\n' "$family" > "$WAYBAR_DIR/style.css"
fi

if [ -n "$sel_cfg" ]; then
  ln -sfn "$sel_cfg" "$WAYBAR_DIR/config.jsonc"
else
  [ -f "$WAYBAR_DIR/config.jsonc" ] || printf '{}\n' >"$WAYBAR_DIR/config.jsonc"
fi
ln -sfn "$WAYBAR_DIR/config.jsonc" "$WAYBAR_DIR/config"

# ---- reload ----
if systemctl --user is-active --quiet "$SERVICE"; then
  systemctl --user reload-or-restart "$SERVICE" >/dev/null 2>&1 || true
else
  pkill -USR2 -x waybar >/dev/null 2>&1 || true
fi

printf 'Waybar theme: Applied: %s\n' "$SEL"

