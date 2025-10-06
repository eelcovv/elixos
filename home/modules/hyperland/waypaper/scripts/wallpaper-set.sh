#!/usr/bin/env bash
# ~/.local/bin/wallpaper-set.sh
# English comments inside the code block.
# Purpose:
# - Accept a basename (no extension) or a path (with or without extension)
# - Resolve extension order: png → jpg/jpeg → webp (also uppercase variants)
# - Always relay to wallpaper.sh with --image; optional --effect KEYWORD override
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
EFFECT="${WALLPAPER_EFFECT:-}"  # optional override via env or --effect

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dir DIR] [--effect KEYWORD] <name-or-path>

If <name-or-path> is a basename, it will be searched under DIR with:
  .png, .jpg/.jpeg, .webp (case-insensitive)
If it's a path without extension, the same extension search is done at that path.
Always calls: wallpaper.sh --image <resolved>
EOF
  exit 1
}

# Helper: try a list of extensions against a stem (path without extension)
try_exts() {
  local stem="$1"; shift || true
  local exts=("$@")
  local cand
  for ext in "${exts[@]}"; do
    cand="${stem}.${ext}"
    [[ -f "$cand" ]] && { printf '%s\n' "$cand"; return 0; }
  done
  return 1
}

# Args
[[ $# -gt 0 ]] || usage
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)    [[ $# -ge 2 ]] || usage; DIR="$2"; shift 2 ;;
    --effect) [[ $# -ge 2 ]] || usage; EFFECT="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) break ;;
  esac
done
[[ $# -ge 1 ]] || usage

INPUT="$1"
[[ "$INPUT" == ~* ]] && INPUT="${INPUT/#\~/$HOME}"

# Resolve final file F:
# - Path with extension → use as-is (must exist)
# - Path without extension → try extensions in order
# - Basename (maybe with extension) → resolve under $DIR
F=""

if [[ "$INPUT" == /* || "$INPUT" == ./* || "$INPUT" == ../* ]]; then
  # Looks like a path
  if [[ "$INPUT" == *.* ]]; then
    F="$INPUT"
    [[ -f "$F" ]] || { echo ":: Not found: $F" >&2; exit 1; }
  else
    if F="$(try_exts "$INPUT" png PNG jpg JPG jpeg JPEG webp WEBP)"; then :; else
      echo ":: Not found: $INPUT.(png|jpg|jpeg|webp)" >&2; exit 1
    fi
  fi
else
  # Treat as basename inside DIR
  if [[ "$INPUT" == *.* ]]; then
    F="$DIR/$INPUT"
    [[ -f "$F" ]] || { echo ":: Not found: $F" >&2; exit 1; }
  else
    if F="$(try_exts "$DIR/$INPUT" png PNG jpg JPG jpeg JPEG webp WEBP)"; then :; else
      echo ":: Not found: $DIR/$INPUT.(png|jpg|jpeg|webp)" >&2; exit 1
    fi
  fi
fi

# Relay into the pipeline; let wallpaper.sh handle theming/effects.
if [[ -n "$EFFECT" ]]; then
  exec "$HOME/.local/bin/wallpaper.sh" --image "$F" --effect "$EFFECT"
else
  exec "$HOME/.local/bin/wallpaper.sh" --image "$F"
fi

