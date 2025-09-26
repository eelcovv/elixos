#!/usr/bin/env bash
# Switch Waybar theme family + variant by updating symlinks only.
set -euo pipefail

FAMILY="${1:-ml4w-blur}"         # bv. ml4w-modern
VARIANT="${2:-light}"            # bv. black
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"

fam_dir="$CFG/themes/$FAMILY"
[ -d "$fam_dir" ] || { echo "Unknown family: $FAMILY"; exit 1; }

# 1) current -> family
ln -sfnT "$fam_dir" "$CFG/current"

# 2) active -> current/<variant> (of current als variant ontbreekt)
if [ -d "$CFG/current/$VARIANT" ]; then
  ln -sfnT "$CFG/current/$VARIANT" "$CFG/active"
else
  ln -sfnT "$CFG/current" "$CFG/active"
fi

# 3) style.css (top-level) -> current/style.css (family base)
if [ -f "$CFG/current/style.css" ]; then
  ln -sfn "$CFG/current/style.css" "$CFG/style.css"
fi

# 4) colors: zorg dat active/colors.css bestaat (variant > family > fallback)
if [ ! -e "$CFG/active/colors.css" ]; then
  if [ -e "$CFG/current/colors.css" ]; then
    ln -sfn "$CFG/current/colors.css" "$CFG/active/colors.css"
  elif [ -e "$CFG/colors.css" ]; then
    ln -sfn "$CFG/colors.css" "$CFG/active/colors.css"
  fi
fi

echo "Switched to family='$FAMILY' variant='${VARIANT}'"

