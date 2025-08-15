#!/usr/bin/env bash
# List available wallpapers in columns, grouped by basename with available extensions
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
ABS=0

usage() {
  echo "Usage: $(basename "$0") [--dir DIR] [--absolute]"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)       DIR="$2"; shift 2 ;;
    --absolute|-a) ABS=1; shift ;;
    -h|--help)   usage ;;
    *)           echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

shopt -s nullglob

declare -A exts

# Process .png first, then .jpg, to keep display order as "png,jpg" when both exist
for f in "$DIR"/*.png "$DIR"/*.jpg; do
  [[ -e "$f" ]] || continue
  base="$(basename "$f")"
  ext="${base##*.}"
  name="${base%.*}"
  disp="$name"
  [[ "$ABS" -eq 1 ]] && disp="$DIR/$name"

  if [[ -v exts["$disp"] ]]; then
    # Avoid duplicate appends if any
    case ",${exts["$disp"]}," in
      *",$ext,"*) : ;;
      *) exts["$disp"]="${exts["$disp"]},$ext" ;;
    esac
  else
    exts["$disp"]="$ext"
  fi
done

if [[ ${#exts[@]} -eq 0 ]]; then
  echo "(none)"
  exit 0
fi

{
  for k in "${!exts[@]}"; do
    echo "$k (${exts[$k]})"
  done
} | sort | { command -v column >/dev/null 2>&1 && column || cat; }
