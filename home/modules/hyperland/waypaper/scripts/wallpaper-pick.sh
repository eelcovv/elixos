#!/usr/bin/env bash
# Pick a wallpaper from a menu (rofi with wofi fallback) and apply via wallpaper-set.sh.
# Falls back to calling wallpaper.sh with a resolved path if wallpaper-set.sh is missing.
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
ROFI_CFG="${ROFI_CONFIG:-$HOME/.config/rofi/config.rasi}"
CACHE_FILE="$HOME/.cache/hyprlock-assets/current_wallpaper"

HELPER="$HOME/.config/hypr/scripts/helper-functions.sh"
if [[ -r "$HELPER" ]]; then
  # shellcheck disable=SC1090
  source "$HELPER" || true
fi
if [[ "$(type -t notify 2>/dev/null)" != "function" ]]; then
  notify() { printf '%s: %s\n' "wallpaper-pick" "$*"; }
fi

# --- args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--dir DIR]
Pick a wallpaper from DIR (default: $DIR) and apply it via wallpaper-set.sh.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

shopt -s nullglob

# Collect bases & extensions
declare -A have_png have_jpg have_webp
for f in "$DIR"/*.png; do base="$(basename "${f%.*}")"; have_png["$base"]=1; done
for f in "$DIR"/*.jpg; do base="$(basename "${f%.*}")"; have_jpg["$base"]=1; done
for f in "$DIR"/*.webp; do base="$(basename "${f%.*}")"; have_webp["$base"]=1; done

# Nothing to show?
if [[ ${#have_png[@]} -eq 0 && ${#have_jpg[@]} -eq 0 && ${#have_webp[@]} -eq 0]]; then
  notify "No wallpapers found in $DIR (png/jpg)"
  exit 0
fi

# Current base (from cached source path)
current_base=""
if [[ -f "$CACHE_FILE" ]]; then
  cur="$(<"$CACHE_FILE")"
  [[ "$cur" == ~* ]] && cur="${cur/#\~/$HOME}"
  bn="$(basename "$cur")"
  current_base="${bn%.*}"
fi

# Build label->base map
labels=()
bases=()
mapfile -t all_bases < <(printf '%s\n' "${!have_png[@]}" "${!have_jpg[@]}" "${!have_webp[@]}"| sort -fu)
for b in "${all_bases[@]}"; do
  exts=""
  [[ ${have_png[$b]+x} ]] && exts="png"
  [[ ${have_jpg[$b]+x} ]] && exts="${exts:+$exts,}jpg"
  [[ ${have_webp[$b]+x} ]] && exts="${exts:+$exts,}webp"
  label="$b ($exts)"
  [[ "$b" == "$current_base" ]] && label="$label  [current]"
  labels+=("$label")
  bases+=("$b")
done

# Add Random at top
labels=("Random" "${labels[@]}")
bases=("" "${bases[@]}")

# Menu (rofi preferred, wofi fallback)
pick_menu() {
  if command -v rofi >/dev/null 2>&1; then
    printf '%s\n' "${labels[@]}" | rofi -dmenu -i -no-show-icons -p "Wallpaper" -l 20 -config "$ROFI_CFG"
  elif command -v wofi >/dev/null 2>&1; then
    printf '%s\n' "${labels[@]}" | wofi --dmenu --prompt "Wallpaper" --allow-markup
  else
    printf '%s\n' "${labels[@]}" | fzf --prompt="Wallpaper> " || true
  fi
}

choice="$(pick_menu)"
[[ -n "${choice:-}" ]] || exit 0
choice="${choice%%  [current]*}"

# Random?
if [[ "$choice" == "Random" ]]; then
  exec "$HOME/.local/bin/wallpaper-random.sh"
fi

# Resolve selected base
sel_base=""
for i in "${!labels[@]}"; do
  if [[ "${labels[$i]}" == "$choice" ]]; then
    sel_base="${bases[$i]}"
    break
  fi
done
[[ -n "$sel_base" ]] || { notify "Selection not recognized"; exit 1; }

# Prefer .png, then .jpg, then webp (for fallback path-mode)
resolved=""
if [[ -f "$DIR/$sel_base.png" ]]; then
  resolved="$DIR/$sel_base.png"
elif [[ -f "$DIR/$sel_base.jpg" ]]; then
  resolved="$DIR/$sel_base.jpg"
elif [[ -f "$DIR/$sel_base.webp" ]]; then
  resolved="$DIR/$sel_base.webp"
fi

# Primary: use wallpaper-set.sh with basename (lets it resolve png/jpg itself)
if [[ -x "$HOME/.local/bin/wallpaper-set.sh" ]]; then
  notify "Applying (via wallpaper-set.sh): $sel_base"
  exec "$HOME/.local/bin/wallpaper-set.sh" "$sel_base"
fi

# Fallback: call wallpaper.sh with the resolved full path
if [[ -n "$resolved" ]]; then
  notify "Applying (via wallpaper.sh): $resolved"
  exec "$HOME/.local/bin/wallpaper.sh" "$resolved"
fi

notify "Missing files for '$sel_base' in $DIR (.png/.jpg/.webp)"; exit 1

