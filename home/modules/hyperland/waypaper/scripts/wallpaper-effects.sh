#!/usr/bin/env bash
# Menu to pick an effect keyword, persist it to effect.conf, and apply immediately.

set -euo pipefail

CONF="$HOME/.config/hypr/settings/effect.conf"
EFFECTS_DIR="$HOME/.config/hypr/effects/wallpaper"
CACHE_FILE="$HOME/.cache/hyprlock-assets/current_wallpaper"

# Ensure dirs exist
mkdir -p "$(dirname "$CONF")"

# Collect available effects = filenames under $EFFECTS_DIR plus "off"
declare -a choices
choices=("off")
if [[ -d "$EFFECTS_DIR" ]]; then
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    choices+=("$base")
  done < <(find "$EFFECTS_DIR" -maxdepth 1 -type f -perm -u=x -print0 2>/dev/null)
fi

# Current effect (from conf if present)
current="off"
if [[ -r "$CONF" ]]; then
  current="$(tr -d '\r' < "$CONF" | awk 'NF{print $1; exit}')"
fi

# Build menu with [current] tag
declare -a labels
for c in "${choices[@]}"; do
  lab="$c"
  [[ "$c" == "$current" ]] && lab="$lab  [current]"
  labels+=("$lab")
done

pick_menu() {
  if command -v rofi >/dev/null 2>&1; then
    printf '%s\n' "${labels[@]}" | rofi -dmenu -i -no-show-icons -p "Effect" -l 15
  elif command -v wofi >/dev/null 2>&1; then
    printf '%s\n' "${labels[@]}" | wofi --dmenu --prompt "Effect" --allow-markup
  else
    printf '%s\n' "${labels[@]}" | fzf --prompt="Effect> " || true
  fi
}

choice="$(pick_menu)"
[[ -n "${choice:-}" ]] || exit 0
choice="${choice%%  [current]*}"

# Validate choice (must be "off" or an executable file under EFFECTS_DIR)
if [[ "$choice" != "off" ]]; then
  if [[ ! -x "$EFFECTS_DIR/$choice" ]]; then
    printf 'Effect script not found or not executable: %s\n' "$EFFECTS_DIR/$choice" >&2
    exit 1
  fi
fi

# Persist to effect.conf (single keyword)
printf '%s\n' "$choice" > "$CONF"

# Apply immediately to current wallpaper (if we have one)
if [[ -r "$CACHE_FILE" ]]; then
  img="$(<"$CACHE_FILE")"
  [[ "$img" == ~* ]] && img="${img/#\~/$HOME}"
  if [[ -f "$img" ]]; then
    # Call pipeline with explicit override so we see effect right away
    QUIET=0 "$HOME/.local/bin/wallpaper.sh" --image "$img" --effect "$choice" --verbose || true
    exit 0
  fi
fi

# No current image → just notify
if command -v notify-send >/dev/null 2>&1; then
  notify-send "Wallpaper effect set" "$choice"
else
  printf 'Wallpaper effect set: %s\n' "$choice"
fi

