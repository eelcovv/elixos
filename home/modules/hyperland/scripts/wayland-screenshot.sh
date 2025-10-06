#!/usr/bin/env bash
# Wayland screenshot helper for Hyprland using grim+slurp (+ wl-copy, swappy/satty)
# Usage:
#   wayland-screenshot.sh area-save
#   wayland-screenshot.sh area-clipboard
#   wayland-screenshot.sh area-annotate
#   wayland-screenshot.sh area-annotate-satty
#   wayland-screenshot.sh full-save
#   wayland-screenshot.sh full-clipboard
set -euo pipefail

DIR="${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
mkdir -p "$DIR"

timestamp() { date +'%Y-%m-%d_%H-%M-%S'; }
file_png="$DIR/screenshot_$(timestamp).png"

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -a "Screenshot" "$1" "$2" || true
}

cmd="${1:-}"
case "$cmd" in
  area-save)
    grim -g "$(slurp)" "$file_png"
    notify "Saved" "$file_png"
    echo "$file_png"
    ;;
  area-clipboard)
    grim -g "$(slurp)" - | wl-copy --type image/png
    notify "Copied to clipboard" "Selection captured"
    ;;
  area-annotate)
    # Requires swappy
    grim -g "$(slurp)" - | swappy -f -
    ;;
  area-annotate-satty)
    # Requires satty; falls back to swappy if satty is missing
    if command -v satty >/dev/null 2>&1; then
      grim -g "$(slurp)" - | satty -f - --copy-command wl-copy
    else
      grim -g "$(slurp)" - | swappy -f -
    fi
    ;;
  full-save)
    grim "$file_png"
    notify "Saved" "$file_png"
    echo "$file_png"
    ;;
  full-clipboard)
    grim - | wl-copy --type image/png
    notify "Copied to clipboard" "Full screen captured"
    ;;
  *)
    echo "Usage: $0 {area-save|area-clipboard|area-annotate|area-annotate-satty|full-save|full-clipboard}" >&2
    exit 2
    ;;
esac
