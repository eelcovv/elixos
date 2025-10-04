#!/usr/bin/env bash
# Set a wallpaper by name or path and relay to wallpaper.sh.
# English comments inside the code block.
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
EFFECT="${WALLPAPER_EFFECT:-}"  # optional override

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dir DIR] [--effect KEYWORD] <name|path>
Tries .png, .jpg, .webp for basenames; passes final file to wallpaper.sh.
EOF
  exit 1
}

# Args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)      [[ $# -ge 2 ]] || usage; DIR="$2"; shift 2 ;;
    --effect)   [[ $# -ge 2 ]] || usage; EFFECT="$2"; shift 2 ;;
    -h|--help)  usage ;;
    *)          break ;;
  esac
done

[[ $# -ge 1 ]] || usage
INPUT="$1"

# Expand ~ and resolve final file F (same logic as you already had) ...
[[ "$INPUT" == ~* ]] && INPUT="${INPUT/#\~/$HOME}"
if [[ "$INPUT" == /* || "$INPUT" == ./* || "$INPUT" == ../* ]]; then
  if [[ "$INPUT" == *.* ]]; then
    F="$INPUT"; [[ -f "$F" ]] || { echo ":: Not found: $F" >&2; exit 1; }
  else
    for ext in png jpg webp; do
      [[ -f "$INPUT.$ext" ]] && { F="$INPUT.$ext"; break; }
    done
    [[ -n "${F:-}" ]] || { echo ":: Not found: $INPUT.(png|jpg|webp)" >&2; exit 1; }
  fi
else
  if [[ "$INPUT" == *.* ]]; then
    F="$DIR/$INPUT"; [[ -f "$F" ]] || { echo ":: Not found: $F" >&2; exit 1; }
  else
    for ext in png jpg webp; do
      [[ -f "$DIR/$INPUT.$ext" ]] && { F="$DIR/$INPUT.$ext"; break; }
    done
    [[ -n "${F:-}" ]] || { echo ":: Not found: $DIR/$INPUT.(png|jpg|webp)" >&2; exit 1; }
  fi
fi

# Relay to wallpaper.sh; let it load effect from effect.conf unless overridden
if [[ -n "$EFFECT" ]]; then
  exec "$HOME/.local/bin/wallpaper.sh" --image "$F" --effect "$EFFECT"
else
  exec "$HOME/.local/bin/wallpaper.sh" --image "$F"
fi

