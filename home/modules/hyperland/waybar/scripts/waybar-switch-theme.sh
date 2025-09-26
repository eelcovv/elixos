#!/usr/bin/env bash
set -euo pipefail
# Switch Waybar theme using ONLY symlinks, with a single stable shim dir:
#   ~/.config/waybar/variant/
# - HM owns ~/.config/waybar/config.jsonc (wrapper) – we don't touch it.
# - Top-level ~/.config/waybar/style.css -> themes/<family>/style.css (family base)
# - Variant mode:
#     ~/.config/waybar/variant/style.css  -> themes/<family>/<variant>/style.css
#     ~/.config/waybar/variant/colors.css -> ~/.config/waybar/colors.css
#     ~/.config/waybar/variant/themes     -> ~/.config/waybar/themes
#     ~/.config/waybar/active             -> ~/.config/waybar/variant
# - Base mode (no variant):
#     ~/.config/waybar/active             -> ~/.config/waybar
# Start Waybar with: -s ~/.config/waybar/active/style.css

usage() { echo "Usage: $(basename "$0") <family> [<variant>|base]"; exit 2; }

[[ $# -ge 1 ]] || usage
FAMILY="$1"
VARIANT="${2:-base}"

WB="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$WB/themes"

FAMILY_BASE="$THEMES/$FAMILY/style.css"
[[ -e "$FAMILY_BASE" ]] || { echo "Missing family base: $FAMILY_BASE" >&2; exit 3; }

# 1) Point top-level base to the family base (for ../style.css in variant css)
ln -sfn "$FAMILY_BASE" "$WB/style.css"

MODE="base"
REAL_VAR="-"

# 2) Variant mode uses a single stable shim directory: ~/.config/waybar/variant
if [[ "$VARIANT" != "base" && -e "$THEMES/$FAMILY/$VARIANT/style.css" ]]; then
  VAR_DIR="$WB/variant"
  # Ensure VAR_DIR is a real directory (not a symlink); recreate if necessary
  if [[ -L "$VAR_DIR" || ( -e "$VAR_DIR" && ! -d "$VAR_DIR" ) ]]; then
    rm -f "$VAR_DIR"
  fi
  mkdir -p "$VAR_DIR"

  ln -sfn "$THEMES/$FAMILY/$VARIANT/style.css" "$VAR_DIR/style.css"
  ln -sfn "$WB/colors.css"                      "$VAR_DIR/colors.css"
  ln -sfn "$WB/themes"                          "$VAR_DIR/themes"

  ln -sfn "$VAR_DIR" "$WB/active"
  MODE="variant"
  REAL_VAR="$(realpath "$VAR_DIR/style.css" 2>/dev/null || echo '?')"
else
  # 3) Base mode: point active to top-level (family base)
  ln -sfn "$WB" "$WB/active"
fi

REAL_BASE="$(realpath "$WB/style.css" 2>/dev/null || echo '?')"

echo "Switched to family='$FAMILY' variant='${VARIANT:-base}' mode=$MODE"
echo "Base CSS   : $REAL_BASE"
echo "Variant CSS: $REAL_VAR"
echo "Waybar CSS : $WB/active/style.css"

# Restart Waybar quietly
pkill waybar || true
waybar -l trace -c "$WB/config.jsonc" -s "$WB/active/style.css" >/dev/null 2>&1 &
disown || true

# Desktop notification (optional)
if command -v notify-send >/dev/null 2>&1; then
  BODY="Family: $FAMILY
Variant: $VARIANT ($MODE)
Base: $(basename "$REAL_BASE")
Variant: $(basename "$REAL_VAR")"
  notify-send "Waybar theme switched" "$BODY"
fi

