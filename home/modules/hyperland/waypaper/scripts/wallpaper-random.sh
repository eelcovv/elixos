#!/usr/bin/env bash
# Pick a random wallpaper (.png/.jpg) and set it via Waypaper
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
BACKEND="${WALLPAPER_BACKEND:-hyprpaper}"

usage() {
  echo "Usage: $(basename "$0") [--dir DIR] [--backend BACKEND]"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)      DIR="$2"; shift 2 ;;
    --backend)  BACKEND="$2"; shift 2 ;;
    -h|--help)  usage ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

shopt -s nullglob
mapfile -t files < <(find "$DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' \) -print)
if [[ ${#files[@]} -eq 0 ]]; then
  echo ":: No wallpapers found in $DIR (png/jpg)" >&2
  exit 1
fi

# Kies willekeurig
idx=$(( RANDOM % ${#files[@]} ))
F="${files[$idx]}"

echo ":: Random wallpaper: $F"
waypaper --backend "$BACKEND" --folder "$DIR" --wallpaper "$F"
