#!/usr/bin/env bash
# ~/.local/bin/wallpaper-pick.sh
# Purpose:
# - Show a menu of wallpapers by basename (supports png/jpg/jpeg/webp; case-insensitive)
# - Prefer to call wallpaper-set.sh with the basename (it resolves extensions)
# - Fallback: resolve a full path here and call wallpaper.sh directly
# - Optional: pass an effect override via --effect or WALLPAPER_EFFECT
set -euo pipefail

DIR="${WALLPAPER_DIR:-$HOME/.config/wallpapers}"
ROFI_CFG="${ROFI_CONFIG:-$HOME/.config/rofi/config.rasi}"
CACHE_FILE="$HOME/.cache/hyprlock-assets/current_wallpaper"
EFFECT_OVERRIDE="${WALLPAPER_EFFECT:-}"  # optional effect override

# Optional notify() helper from your shared helpers
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
    --dir)    DIR="$2"; shift 2 ;;
    --effect) EFFECT_OVERRIDE="$2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--dir DIR] [--effect KEYWORD]
Pick a wallpaper from DIR and apply it via wallpaper-set.sh.
Falls back to wallpaper.sh with a resolved path if needed.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

shopt -s nullglob

# Collect bases per extension (png/jpg/jpeg/webp, case-insensitive)
declare -A have_png have_jpg have_webp
for f in "$DIR"/*.png "$DIR"/*.PNG;   do [[ -e "$f" ]] || continue; base="$(basename "${f%.*}")"; have_png["$base"]=1; done
for f in "$DIR"/*.jpg "$DIR"/*.JPG \
         "$DIR"/*.jpeg "$DIR"/*.JPEG; do [[ -e "$f" ]] || continue; base="$(basename "${f%.*}")"; have_jpg["$base"]=1; done
for f in "$DIR"/*.webp "$DIR"/*.WEBP; do [[ -e "$f" ]] || continue; base="$(basename "${f%.*}")"; have_webp["$base"]=1; done

# Nothing to show?
if [[ ${#have_png[@]} -eq 0 && ${#have_jpg[@]} -eq 0 && ${#have_webp[@]} -eq 0 ]]; then
  notify "No wallpapers found in $DIR (png/jpg/jpeg/webp)"
  exit 0
fi

# Current base (from cached full path)
current_base=""
if [[ -f "$CACHE_FILE" ]]; then
  cur="$(<"$CACHE_FILE")"
  [[ "$cur" == ~* ]] && cur="${cur/#\~/$HOME}"
  bn="$(basename "$cur")"
  current_base="${bn%.*}"
fi

# Build menu labels (basename + extensions list)
labels=()
bases=()
mapfile -t all_bases < <(printf '%s\n' "${!have_png[@]}" "${!have_jpg[@]}" "${!have_webp[@]}" | sort -fu)
for b in "${all_bases[@]}"; do
  exts=()
  [[ ${have_png[$b]+x}  ]] && exts+=("png")
  [[ ${have_jpg[$b]+x}  ]] && exts+=("jpg/jpeg")
  [[ ${have_webp[$b]+x} ]] && exts+=("webp")
  label="$b ($(IFS=,; echo "${exts[*]}"))"
  [[ "$b" == "$current_base" ]] && label="$label  [current]"
  labels+=("$label")
  bases+=("$b")
done

# Add Random
labels=("Random" "${labels[@]}")
bases=("" "${bases[@]}")

# Menu (rofi preferred, wofi fallback, else fzf)
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

# Random path
if [[ "$choice" == "Random" ]]; then
  if [[ -n "$EFFECT_OVERRIDE" ]]; then
    exec "$HOME/.local/bin/wallpaper-random.sh" --effect "$EFFECT_OVERRIDE"
  else
    exec "$HOME/.local/bin/wallpaper-random.sh"
  fi
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

# Primary path: use wallpaper-set.sh with basename (it resolves extensions)
if [[ -x "$HOME/.local/bin/wallpaper-set.sh" ]]; then
  notify "Applying (via wallpaper-set.sh): $sel_base"
  if [[ -n "$EFFECT_OVERRIDE" ]]; then
    exec "$HOME/.local/bin/wallpaper-set.sh" --effect "$EFFECT_OVERRIDE" "$sel_base"
  else
    exec "$HOME/.local/bin/wallpaper-set.sh" "$sel_base"
  fi
fi

# Fallback: resolve a full path here (png → jpg/jpeg → webp; case-insensitive)
resolved=""
for ext in png PNG jpg JPG jpeg JPEG webp WEBP; do
  if [[ -f "$DIR/$sel_base.$ext" ]]; then
    resolved="$DIR/$sel_base.$ext"
    break
  fi
done

if [[ -n "$resolved" ]]; then
  notify "Applying (via wallpaper.sh): $resolved"
  if [[ -n "$EFFECT_OVERRIDE" ]]; then
    exec "$HOME/.local/bin/wallpaper.sh" --image "$resolved" --effect "$EFFECT_OVERRIDE"
  else
    exec "$HOME/.local/bin/wallpaper.sh" --image "$resolved"
  fi
fi

notify "Missing files for '$sel_base' in $DIR (.png/.jpg/.jpeg/.webp)"; exit 1

