#!/usr/bin/env bash
# Set a wallpaper via Waypaper; extension is optional.
# - Without extension: try .png first, then .jpg
# - With path or extension: use exactly that file
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
BACKEND="${WALLPAPER_BACKEND:-hyprpaper}"

usage() {
  echo "Usage: $(basename "$0") [--dir DIR] [--backend BACKEND] <name|path>"
  exit 1
}

# Args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)      [[ $# -ge 2 ]] || usage; DIR="$2"; shift 2 ;;
    --backend)  [[ $# -ge 2 ]] || usage; BACKEND="$2"; shift 2 ;;
    -h|--help)  usage ;;
    *)          break ;;
  esac
done

[[ $# -ge 1 ]] || usage
INPUT="$1"

# Expand ~
if [[ "$INPUT" == ~* ]]; then
  INPUT="${INPUT/#\~/$HOME}"
fi

# Decide final file F
if [[ "$INPUT" == /* || "$INPUT" == ./* || "$INPUT" == ../* ]]; then
  # Treat as path
  if [[ "$INPUT" == *.* ]]; then
    F="$INPUT"
    [[ -f "$F" ]] || { echo ":: Not found: $F" >&2; exit 1; }
  else
    if [[ -f "$INPUT.png" ]]; then
      F="$INPUT.png"
    elif [[ -f "$INPUT.jpg" ]]; then
      F="$INPUT.jpg"
    else
      echo ":: Not found: $INPUT.(png|jpg)" >&2; exit 1
    fi
  fi
else
  # Treat as name inside $DIR
  if [[ "$INPUT" == *.* ]]; then
    F="$DIR/$INPUT"
    [[ -f "$F" ]] || { echo ":: Not found: $F" >&2; exit 1; }
  else
    if [[ -f "$DIR/$INPUT.png" ]]; then
      F="$DIR/$INPUT.png"
    elif [[ -f "$DIR/$INPUT.jpg" ]]; then
      F="$DIR/$INPUT.jpg"
    else
      echo ":: Not found: $DIR/$INPUT.(png|jpg)" >&2; exit 1
    fi
  fi
fi

echo ":: Setting wallpaper: $F"
waypaper --backend "$BACKEND" --folder "$DIR" --wallpaper "$F"
