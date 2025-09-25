#!/usr/bin/env bash
# Set a wallpaper by name or path.
# - Without extension: try .png first, then .jpg
# - With path or extension: use exactly that file
# Always route via wallpaper.sh (effects + theming). No direct Waypaper call.
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dir DIR] <name|path>

Always routes via wallpaper.sh (no --raw mode in this variant).
EOF
  exit 1
}

# Args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)      [[ $# -ge 2 ]] || usage; DIR="$2"; shift 2 ;;
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
    elif [[ -f "$INPUT.webp" ]]; then
      F="$INPUT.webp"
    else
      echo ":: Not found: $INPUT.(png|jpg|webp)" >&2; exit 1
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
    elif [[ -f "$DIR/$INPUT.webp" ]]; then
      F="$DIR/$INPUT.webp"
    else
      echo ":: Not found: $DIR/$INPUT.(png|jpg|webp)" >&2; exit 1
    fi
  fi
fi

echo ":: Setting via pipeline: $F"
exec "$HOME/.local/bin/wallpaper.sh" "$F"