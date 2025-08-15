#!/usr/bin/env bash
# Pick an effect and re-apply the current wallpaper via wallpaper.sh (so effects are generated)
set -euo pipefail

hypr_cache_folder="$HOME/.cache/hyprlock-assets"
cache_file="$hypr_cache_folder/current_wallpaper"
effect_file="$HOME/.config/hypr/settings/wallpaper-effect.sh"
effects_dir="$HOME/.config/hypr/effects/wallpaper"
rofi_config="${ROFI_CONFIG:-$HOME/.config/rofi/config.rasi}"

usage() { echo "Usage: $(basename "$0") [reload]"; exit 0; }

if [[ "${1:-}" == "reload" ]]; then
  if [[ -f "$cache_file" ]]; then
    wp="$(sed 's|~|'"$HOME"'|g' "$cache_file")"
    exec "$HOME/.local/bin/wallpaper.sh" "$wp"
  else
    notify-send "Wallpaper Effect" "No cached wallpaper found."
    exit 1
  fi
fi

opts="$(ls -1 "$effects_dir" 2>/dev/null)$'\n'off"
choice="$(printf "%s\n" "$opts" | rofi -dmenu -config "$rofi_config" -i -no-show-icons -l 12 -p "Effect")"
[[ -n "${choice:-}" ]] || exit 0

printf "%s\n" "$choice" > "$effect_file"
notify-send "Wallpaper Effect" "Applying: $choice"

if [[ -f "$cache_file" ]]; then
  wp="$(sed 's|~|'"$HOME"'|g' "$cache_file")"
  exec "$HOME/.local/bin/wallpaper.sh" "$wp"
else
  notify-send "Wallpaper Effect" "Saved. Will apply on next change."
fi

