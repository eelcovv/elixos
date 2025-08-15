#!/usr/bin/env bash
# Set a wallpaper by name or path.
# - Without extension: try .png first, then .jpg
# - With path or extension: use exactly that file
# Default: route via wallpaper.sh (effects + theming). Use --raw to call waypaper directly.
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
BACKEND="${WALLPAPER_BACKEND:-hyprpaper}"
RAW=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dir DIR] [--backend BACKEND] [--raw] <name|path>

--raw   Bypass pipeline and call waypaper directly (no effects/matugen/wallust).
EOF
  exit 1
}

# Args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)      [[ $# -ge 2 ]] || usage; DIR="$2"; shift 2 ;;
    --backend)  [[ $# -ge 2 ]] || usage; BACKEND="$2"; shift 2 ;;
    --raw)      RAW=1; shift ;;
    -h|--help)  usage ;;
    *)          break ;;
  esac
done

[[ $# -ge 1 ]] || usage
INPUT="$1"

# Expand ~
[[ "$INPUT" == ~* ]] && INPUT="${INPUT/#\~/$HOME}"

# Resolve final file F
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

# Prefer pipeline (effects + theming)
if [[ "$RAW" -eq 0 ]]; then
  echo ":: Setting via pipeline: $F"
  exec "$HOME/.local/bin/wallpaper.sh" "$F"
fi

# Raw mode: direct waypaper
echo ":: Setting (raw) wallpaper: $F"
WP_DIR="$(dirname "$F")"
waypaper --backend "$BACKEND" --folder "$WP_DIR" --wallpaper "$F"

