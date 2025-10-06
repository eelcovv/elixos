#!/usr/bin/env bash
# Pick a random wallpaper from $WALLPAPER_DIR (or default) and set it
# by calling wallpaper.sh exactly once (no direct Waypaper call).
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
QUIET="${QUIET:-1}"
RESPECT_FULLSCREEN="${RESPECT_FULLSCREEN:-1}"
EFFECT_OVERRIDE="${WALLPAPER_EFFECT:-}"  # optional

log() { [ "$QUIET" = "1" ] || printf '%s\n' "$*"; }

usage() {
  echo "Usage: $(basename "$0") [--dir DIR] [--verbose] [--no-fullscreen-check] [--effect KEYWORD]"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    --verbose) QUIET="0"; shift ;;
    --no-fullscreen-check) RESPECT_FULLSCREEN="0"; shift ;;
    --effect) EFFECT_OVERRIDE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ "$RESPECT_FULLSCREEN" = "1" ]] && command -v hyprctl >/dev/null 2>&1; then
  if hyprctl -j activewindow >/dev/null 2>&1; then
    fs="$(hyprctl -j activewindow | sed -n 's/.*"fullscreen":\s*\(true\|false\).*/\1/p')"
    if [[ "$fs" = "true" ]]; then
      log ":: fullscreen active; skipping wallpaper change"
      exit 0
    fi
  fi
fi

# Single-run guard
lockfile="/tmp/wallpaper-random.lock"
exec 9>"$lockfile"; flock -n 9 || { log ":: another wallpaper-random is running; skipping"; exit 0; }

shopt -s nullglob
mapfile -t files < <(find "$DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print)
[[ ${#files[@]} -gt 0 ]] || { log ":: No wallpapers found in $DIR"; exit 0; }

idx=$(( RANDOM % ${#files[@]} )); F="${files[$idx]}"
log ":: Random wallpaper: $F"

if [[ -n "$EFFECT_OVERRIDE" ]]; then
  exec "$HOME/.local/bin/wallpaper.sh" --image "$F" --effect "$EFFECT_OVERRIDE"
else
  exec "$HOME/.local/bin/wallpaper.sh" --image "$F"
fi

