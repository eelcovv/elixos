#!/usr/bin/env bash
set -euo pipefail

THEME="${1:-}"
[ -n "$THEME" ] || { echo "Usage: waybar-pick-theme <theme-path>"; exit 2; }

BASE="$HOME/.config/waybar/themes"
[[ -d "$BASE/$THEME" ]] || { echo "Unknown theme variant: $THEME"; exit 1; }

ln -sfn "$BASE/$THEME" "$BASE/current"
systemctl --user restart waybar.service
notify-send "Waybar theme" "Applied: $THEME"

