#!/usr/bin/env bash
# Menu to pick an effect keyword, persist it to effect.conf, and apply immediately.
# Accepts readable files/symlinks (execute bit not required for 'source').

set -euo pipefail

CONF="$HOME/.config/hypr/settings/effect.conf"
EFFECTS_DIR="$HOME/.config/hypr/effects/wallpaper"
CACHE_FILE="$HOME/.cache/hyprlock-assets/current_wallpaper"

mkdir -p "$(dirname "$CONF")"

# Collect effects: include regular files AND symlinks; require readability (-r) only.
choices=(off)
if [[ -d "$EFFECTS_DIR" ]]; then
  while IFS= read -r -d '' f; do
    if [[ (-f "$f" || -L "$f") && -r "$f" ]]; then
      choices+=("$(basename "$f")")
    fi
  done < <(find "$EFFECTS_DIR" -maxdepth 1 \( -type f -o -type l \) -print0 2>/dev/null)
fi

# Current effect
current="off"
if [[ -r "$CONF" ]]; then
  current="$(tr -d '\r' < "$CONF" | awk 'NF{print $1; exit}')"
fi

# Build menu
labels=()
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

choice="$(pick_menu)"; [[ -n "${choice:-}" ]] || exit 0
choice="${choice%%  [current]*}"

# Validate selection: either "off" or readable effect file
if [[ "$choice" != "off" ]]; then
  eff="$EFFECTS_DIR/$choice"
  if [[ ! -e "$eff" || ! -r "$eff" ]]; then
    printf 'Effect script not readable or missing: %s\n' "$eff" >&2
    exit 1
  fi
fi

# Persist
printf '%s\n' "$choice" > "$CONF"

# Apply immediately to current wallpaper (if available)
if [[ -r "$CACHE_FILE" ]]; then
  img="$(<"$CACHE_FILE")"
  [[ "$img" == ~* ]] && img="${img/#\~/$HOME}"
  if [[ -f "$img" ]]; then
    QUIET=0 "$HOME/.local/bin/wallpaper.sh" --image "$img" --effect "$choice" --verbose || true
    exit 0
  fi
fi

printf 'Wallpaper effect set: %s\n' "$choice"

