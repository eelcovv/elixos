#!/usr/bin/env bash
# Pick a random wallpaper (.png/.jpg) and set it via Waypaper (quiet by default).
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
BACKEND="${WALLPAPER_BACKEND:-hyprpaper}"
QUIET="${QUIET:-1}"   # quiet by default; set to 0 or use --verbose to see logs
RESPECT_FULLSCREEN="${RESPECT_FULLSCREEN:-1}"  # skip if fullscreen

log() { [ "$QUIET" = "1" ] || printf '%s\n' "$*"; }

usage() {
  echo "Usage: $(basename "$0") [--dir DIR] [--backend BACKEND] [--verbose] [--no-fullscreen-check]"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)      DIR="$2"; shift 2 ;;
    --backend)  BACKEND="$2"; shift 2 ;;
    --verbose)  QUIET="0"; shift ;;
    --no-fullscreen-check) RESPECT_FULLSCREEN="0"; shift ;;
    -h|--help)  usage ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# optional: skip when a fullscreen window is active (Hyprland)
if [[ "$RESPECT_FULLSCREEN" = "1" ]]; then
  if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl -j activewindow >/dev/null 2>&1; then
      fs="$(hyprctl -j activewindow | sed -n 's/.*"fullscreen":\s*\(true\|false\).*/\1/p')"
      if [[ "$fs" = "true" ]]; then
        log ":: fullscreen active; skipping wallpaper change"
        exit 0
      fi
    fi
  fi
fi

# single-run guard
lockfile="/tmp/wallpaper-random.lock"
exec 9>"$lockfile"
if ! flock -n 9; then
  log ":: another wallpaper-random is running; skipping"
  exit 0
fi

shopt -s nullglob
mapfile -t files < <(find "$DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) -print)
if [[ ${#files[@]} -eq 0 ]]; then
  log ":: No wallpapers found in $DIR (png/jpg)"
  exit 0
fi

# pick random
idx=$(( RANDOM % ${#files[@]} ))
F="${files[$idx]}"

log ":: Random wallpaper: $F"

# Set via Waypaper quietly
if command -v waypaper >/dev/null 2>&1; then
  waypaper --backend "$BACKEND" --folder "$DIR" --wallpaper "$F" >/dev/null 2>&1 || true
fi

# If you also have a local setter, call it quietly:
if [[ -x "$HOME/.local/bin/wallpaper.sh" ]]; then
  "$HOME/.local/bin/wallpaper.sh" "$F" >/dev/null 2>&1 || true
fi

