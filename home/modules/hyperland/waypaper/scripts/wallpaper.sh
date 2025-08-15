#!/usr/bin/env bash
# Pick/apply a wallpaper effect via rofi, with a "None (no effect)" option.
# Also supports CLI:  wallpaper-effects.sh none|off|disable | <effect-name> | reload
set -euo pipefail

# ---- helper + notify fallback ----
HELPER="$HOME/.config/hypr/scripts/helper-functions.sh"
if [[ -r "$HELPER" ]]; then
  # shellcheck disable=SC1090
  source "$HELPER" || true
fi
if [[ "$(type -t notify 2>/dev/null)" != "function" ]]; then
  notify() {
    local title="$1"; shift
    local body="${*:-}"
    printf '%s: %s\n' "$title" "$body"
    command -v logger >/dev/null 2>&1 && logger -t wallpaper-effects -- "$title: $body" || true
    command -v notify-send >/dev/null 2>&1 && notify-send "$title" "$body" || true
  }
fi

effects_dir="$HOME/.config/hypr/effects/wallpaper"
effect_file="$HOME/.config/hypr/settings/wallpaper-effect.sh"
cache_file="$HOME/.cache/hyprlock-assets/current_wallpaper"
rofi_config="${ROFI_CONFIG:-$HOME/.config/rofi/config.rasi}"

current="off"
[[ -f "$effect_file" ]] && current="$(<"$effect_file")"

# Validate effect: only "off" or a file in effects dir is allowed
effects_dir="$HOME/.config/hypr/effects/wallpaper"
[[ "$effect" == ~* ]] && effect="${effect/#\~/$HOME}"
if [[ "$effect" != "off" && ! -r "$effects_dir/$effect" ]]; then
  notify "Effect" "Invalid effect '$effect' → using off"
  effect="off"
fi


apply_current_wallpaper() {
  if [[ -f "$cache_file" ]]; then
    # expand ~ if present
    local wp
    wp="$(sed 's|~|'"$HOME"'|g' "$cache_file")"
    exec "$HOME/.local/bin/wallpaper.sh" "$wp"
  else
    notify "Wallpaper Effect" "Saved '$1'. Will apply on next change."
    exit 0
  fi
}

# ---- CLI mode ----
if [[ $# -gt 0 ]]; then
  case "$1" in
    none|off|disable)
      printf '%s\n' "off" > "$effect_file"
      notify "Wallpaper Effect" "Applying: off"
      apply_current_wallpaper "off"
      ;;
    reload)
      apply_current_wallpaper "reload"
      ;;
    *)
      if [[ -r "$effects_dir/$1" ]]; then
        printf '%s\n' "$1" > "$effect_file"
        notify "Wallpaper Effect" "Applying: $1"
        apply_current_wallpaper "$1"
      else
        notify "Wallpaper Effect" "Unknown effect '$1'"; exit 2
      fi
      ;;
  esac
  exit 0
fi

# ---- Menu mode (rofi) ----
mapfile -t options < <( { printf 'None (no effect)\n'; ls -1 "$effects_dir" 2>/dev/null; } | sed '/^\s*$/d' | sort -f )

# annotate current
annotated=()
for opt in "${options[@]}"; do
  val="$opt"
  [[ "$opt" == "None (no effect)" ]] && val="off"
  label="$opt"
  [[ "$val" == "$current" ]] && label="$label  [current]"
  annotated+=("$label")
done

choice="$(printf '%s\n' "${annotated[@]}" | rofi -dmenu -i -no-show-icons -l 12 -p "Effect" -config "$rofi_config")"
[[ -n "${choice:-}" ]] || exit 0

# strip decoration
choice="${choice%%  [current]*}"
new="$choice"
[[ "$choice" == "None (no effect)" ]] && new="off"

printf '%s\n' "$new" > "$effect_file"
notify "Wallpaper Effect" "Applying: $new"
apply_current_wallpaper "$new"

