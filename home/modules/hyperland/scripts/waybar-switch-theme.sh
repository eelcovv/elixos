#!/usr/bin/env bash
set -euo pipefail

THEME="${1:-}"  # e.g. ml4w/light  (must exist under ~/.config/waybar/themes/)
if [[ -z "$THEME" ]]; then
    echo "Usage: waybar-switch-theme <theme-path>  (e.g., ml4w/light)"
    exit 2
fi

BASE="$HOME/.config/waybar/themes"
if [[ ! -d "$BASE/$THEME" ]]; then
    echo "Unknown theme variant: $THEME"
    exit 1
fi

ln -sfn "$BASE/$THEME" "$BASE/current"
systemctl --user restart waybar.service
notify-send "Waybar theme" "Applied: $THEME"

