#!/usr/bin/env bash
# Minimal mode picker for screenshots (rofi preferred, fallback to wofi)
set -euo pipefail

PICKER=${PICKER:-}
if [[ -z "${PICKER}" ]]; then
  if command -v rofi >/dev/null 2>&1; then
    PICKER="rofi -dmenu -p Screenshot"
  elif command -v wofi >/dev/null 2>&1; then
    PICKER="wofi --dmenu -p Screenshot"
  else
    echo "No rofi/wofi found. Set PICKER env var." >&2
    exit 1
  fi
fi

options=(
  "Area → Save (PNG):::wayland-screenshot.sh area-save"
  "Area → Clipboard:::wayland-screenshot.sh area-clipboard"
  "Area → Annotate (swappy):::wayland-screenshot.sh area-annotate"
  "Area → Annotate (satty):::wayland-screenshot.sh area-annotate-satty"
  "Full → Save (PNG):::wayland-screenshot.sh full-save"
  "Full → Clipboard:::wayland-screenshot.sh full-clipboard"
)

label_list=$(printf '%s\n' "${options[@]}" | cut -d':::' -f1)
choice=$(echo "$label_list" | eval "$PICKER") || exit 0

cmd=$(printf '%s\n' "${options[@]}" | grep -F "$choice" | head -n1 | cut -d':::' -f2-)
exec bash -lc "$cmd"
