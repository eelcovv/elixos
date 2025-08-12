#!/usr/bin/env bash
set -euo pipefail

THEME_DIR="$HOME/.config/waybar/themes"
CONFIG_FILE="$HOME/.config/hypr/settings/current-theme"

# Vind beschikbare subfolders in themes
themes=$(find "$THEME_DIR" -mindepth 2 -maxdepth 2 -type d | sed "s|$THEME_DIR/||")

# Toon selectie in rofi
choice=$(echo "$themes" | rofi -dmenu -p "Select theme")

if [[ -n "$choice" ]]; then
  echo "HOME_THEME=$choice" > "$CONFIG_FILE"
  notify-send "Theme switched" "$choice"
  systemctl --user restart waybar.service
fi
