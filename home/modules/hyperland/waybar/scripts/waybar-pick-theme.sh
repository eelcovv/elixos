#!/usr/bin/env bash
set -euo pipefail

# Script to pick and switch Waybar themes via a menu (wofi/rofi/dmenu).
# Scans ~/.config/waybar/themes for folders containing style.css (excluding assets).

THEMES_DIR="${HOME}/.config/waybar/themes"

# Find all valid themes (folders containing style.css, excluding assets)
mapfile -t THEMES < <(
  find "${THEMES_DIR}" -mindepth 1 -type f -name 'style.css' \
  | grep -v '/assets/' \
  | sed "s#${THEMES_DIR}/##; s#/style.css##" \
  | sort
)

if [[ ${#THEMES[@]} -eq 0 ]]; then
  notify-send "Waybar" "No themes found under ${THEMES_DIR}"
  exit 0
fi

# Use wofi, rofi, or dmenu for theme selection
if command -v wofi >/dev/null 2>&1; then
  CHOICE="$(printf "%s\n" "${THEMES[@]}" | wofi --dmenu --prompt='Waybar theme')" || exit 0
elif command -v rofi >/dev/null 2>&1; then
  CHOICE="$(printf "%s\n" "${THEMES[@]}" | rofi -dmenu -p 'Waybar theme')" || exit 0
else
  CHOICE="$(printf "%s\n" "${THEMES[@]}" | dmenu -p 'Waybar theme')" || exit 0
fi

# Switch theme if selection is not empty
[[ -n "${CHOICE:-}" ]] && exec waybar-switch-theme "${CHOICE}"

