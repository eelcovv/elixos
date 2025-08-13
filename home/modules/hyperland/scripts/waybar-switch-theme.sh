#!/usr/bin/env bash
set -euo pipefail

THEME="${1:-}"  # e.g. ml4w/light
if [[ -z "$THEME" ]]; then
    echo "Usage: waybar-switch-theme <theme-path>  (e.g., ml4w/light)"
    exit 2
fi

BASE="$HOME/.config/waybar/themes"
CUR="$HOME/.config/waybar/current"

if [[ ! -d "$BASE/$THEME" ]]; then
    echo "Unknown theme variant: $THEME"
    exit 1
fi
# Require at least one stylesheet in the variant
if [[ ! -f "$BASE/$THEME/style.css" && ! -f "$BASE/$THEME/style-custom.css" ]]; then
    echo "Variant '$THEME' has no style.css"
    exit 1
fi

ln -sfn "$BASE/$THEME" "$CUR"
systemctl --user restart waybar.service
notify-send "Waybar theme" "Applied: $THEME"

