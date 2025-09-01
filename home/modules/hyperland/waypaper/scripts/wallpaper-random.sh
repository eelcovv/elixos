#!/usr/bin/env bash
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
BACKEND="${WALLPAPER_BACKEND:-hyprpaper}"
QUIET="${QUIET:-1}"
RESPECT_FULLSCREEN="${RESPECT_FULLSCREEN:-1}"

log() { [ "$QUIET" = "1" ] || printf '%s\n' "$*"; }

usage() {
  echo "Usage: $(basename "$0") [--dir DIR] [--backend BACKEND] [--verbose] [--no-fullscreen-check]"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    --backend) BACKEND="$2"; shift 2 ;;
    --verbose) QUIET="0"; shift ;;
    --no-fullscreen-check) RESPECT_FULLSCREEN="0"; shift ;;
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
  log ":: No wallpapers found in $DIR"
  exit 0
fi

# pick random
idx=$(( RANDOM % ${#files[@]} ))
F="${files[$idx]}"
log ":: Random wallpaper: $F"

# Stel via Waypaper in (stil) en roep daarna jouw themingscript aan
command -v waypaper >/dev/null 2>&1 && waypaper --backend "$BACKEND" --folder "$DIR" --wallpaper "$F" >/dev/null 2>&1 || true
[[ -x "$HOME/.local/bin/wallpaper.sh" ]] && "$HOME/.local/bin/wallpaper.sh" "$F" >/dev/null 2>&1 || true

