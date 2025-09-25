#!/usr/bin/env bash
set -euo pipefail
HELPER="$HOME/.config/hypr/scripts/helper-functions.sh"; [[ -r "$HELPER" ]] && source "$HELPER" || true
notify(){ type notify >/dev/null 2>&1 || { notify(){ printf '%s: %s\n' "wallpaper-effects" "$*"; }; }; notify "$@"; }

effects_dir="$HOME/.config/hypr/effects/wallpaper"
effect_file="$HOME/.config/hypr/settings/wallpaper-effect.sh"
cache_file="$HOME/.cache/hyprlock-assets/current_wallpaper"
rofi_config="${ROFI_CONFIG:-$HOME/.config/rofi/config.rasi}"

apply_current() {
  local wp
  if [[ -f "$cache_file" ]]; then
    wp="$(sed 's|~|'"$HOME"'|g' "$cache_file")"
    exec "$HOME/.local/bin/wallpaper.sh" "$wp"
  else
    exit 0
  fi
}

if [[ $# -gt 0 ]]; then
  arg="$1"; [[ "$arg" == ~* ]] && arg="${arg/#\~/$HOME}"
  if [[ -f "$arg" ]] && echo "$arg" | grep -Eiq '\.(png|jpg|webp)$'; then
    printf '%s\n' "$arg" > "$cache_file"; exec "$HOME/.local/bin/wallpaper.sh" "$arg"
  fi
  case "$arg" in
    none|off|disable) printf 'off\n' > "$effect_file"; apply_current ;;
    reload)           apply_current ;;
    *) if [[ -r "$effects_dir/$arg" ]]; then printf '%s\n' "$arg" > "$effect_file"; apply_current
       else notify "Unknown effect '$arg'"; exit 2; fi ;;
  esac
  exit 0
fi

mapfile -t options < <( { printf 'None (no effect)\n'; ls -1 "$effects_dir" 2>/dev/null; } | sed '/^\s*$/d' | sort -f )
current="off"; [[ -f "$effect_file" ]] && current="$(<"$effect_file")"

annotated=(); for opt in "${options[@]}"; do val="$opt"; [[ "$opt" == "None (no effect)" ]] && val="off"
  label="$opt"; [[ "$val" == "$current" ]] && label="$label  [current]"; annotated+=("$label"); done

if command -v rofi >/dev/null 2>&1; then
  choice="$(printf '%s\n' "${annotated[@]}" | rofi -dmenu -i -no-show-icons -l 12 -p "Effect" -config "$rofi_config")"
elif command -v wofi >/dev/null 2>&1; then
  choice="$(printf '%s\n' "${annotated[@]}" | wofi --dmenu --prompt "Effect" --allow-markup)"
else
  choice="$(printf '%s\n' "${annotated[@]}" | fzf --prompt="Effect> " || true)"
fi
[[ -n "${choice:-}" ]] || exit 0
choice="${choice%%  [current]*}"; new="$choice"; [[ "$choice" == "None (no effect)" ]] && new="off"
printf '%s\n' "$new" > "$effect_file"; apply_current

