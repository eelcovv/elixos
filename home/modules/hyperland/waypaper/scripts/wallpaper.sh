#!/usr/bin/env bash
# Apply a wallpaper (met optioneel effect), genereer blurred/square versies
# en draai thema-tools. Gebruikt overal de 'notify' helper (met fallback).
set -euo pipefail

# ---------- Helper laden + fallback notify ----------
HELPER="$HOME/.config/hypr/scripts/helper-functions.sh"
if [[ -r "$HELPER" ]]; then
  # shellcheck disable=SC1090
  source "$HELPER" || true
fi
# Fallback als notify niet bestaat
if [[ "$(type -t notify 2>/dev/null)" != "function" ]]; then
  notify() {
    local title="$1"; shift
    local body="${*:-}"
    printf '%s: %s\n' "$title" "$body"
    if command -v logger >/dev/null 2>&1; then
      logger -t waybar-theme -- "$title: $body"
    fi
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "$title" "$body" || true
    fi
  }
fi

# ---------- Even wachten tot Hyprland monitors heeft ----------
_waitForHypr() {
  if command -v hyprctl >/dev/null 2>&1; then
    for _ in {1..20}; do
      hyprctl monitors -j >/dev/null 2>&1 && return 0
      sleep 0.1
    done
  else
    sleep 0.4
  fi
}

# ---------- Cache & paden ----------
settings_dir="$HOME/.config/hypr/settings"
hypr_cache_folder="$HOME/.cache/hyprlock-assets"
mkdir -p "$hypr_cache_folder"
generatedversions="$hypr_cache_folder/wallpaper-generated"
mkdir -p "$generatedversions"

waypaperrunning="$hypr_cache_folder/waypaper-running"
[[ -f "$waypaperrunning" ]] && rm -f "$waypaperrunning" && exit 0

force_generate=0
cachefile="$hypr_cache_folder/current_wallpaper"
last_applied="$hypr_cache_folder/last_applied"
blurredwallpaper="$hypr_cache_folder/blurred_wallpaper.png"
squarewallpaper="$hypr_cache_folder/square_wallpaper.png"
rasifile="$hypr_cache_folder/current_wallpaper.rasi"
blurfile="$settings_dir/blur.sh"
effectfile="$settings_dir/wallpaper-effect.sh"
defaultwallpaper="$HOME/.config/wallpapers/default.png"

blur="50x30"
[[ -f "$blurfile" ]] && blur="$(<"$blurfile")"

# Aan/uit via presence van settings/wallpaper_cache
use_cache=0
if [[ -f "$settings_dir/wallpaper_cache" ]]; then
  use_cache=1; notify "Wallpaper" "Using cache"
else
  notify "Wallpaper" "Cache disabled"
fi

# ---------- Bron-wallpaper bepalen ----------
if [[ "${1:-}" == "" ]]; then
  wallpaper="$defaultwallpaper"
  [[ -f "$cachefile" ]] && wallpaper="$(<"$cachefile")"
else
  wallpaper="$1"
fi

echo "$wallpaper" > "$cachefile"
tmpwallpaper="$wallpaper"
wallpaperfilename="$(basename "$wallpaper")"
notify "Wallpaper" "Source image: $wallpaperfilename"

# ---------- Effect toepassen (indien gekozen) ----------
effect="off"
[[ -f "$effectfile" ]] && effect="$(<"$effectfile")"

used_wallpaper="$wallpaper"
if [[ "$effect" != "off" ]]; then
  used_wallpaper="$generatedversions/$effect-$wallpaperfilename"
  if [[ -f "$used_wallpaper" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
    notify "Effect" "Use cached: $effect-$wallpaperfilename"
  else
    notify "Effect" "Generate: $effect-$wallpaperfilename"
    # shellcheck disable=SC1090
    source "$HOME/.config/hypr/effects/wallpaper/$effect"
  fi
else
  notify "Effect" "off"
fi

# ---------- Thema alleen bij wijziging ----------
state_key="$effect|$used_wallpaper"
run_theme=1
if [[ -f "$last_applied" ]] && [[ "$state_key" == "$(cat "$last_applied")" ]]; then
  notify "Wallpaper" "Same as last time → skip matugen/wallust"
  run_theme=0
else
  echo "$state_key" > "$last_applied"
fi

# ---------- Wallpaper zetten via Waypaper/Hyprpaper ----------
_waitForHypr
notify "Wallpaper" "Setting: $used_wallpaper"
touch "$waypaperrunning"
waypaper --backend hyprpaper --wallpaper "$used_wallpaper" || notify "Wallpaper" "waypaper failed (ignored)"

# ---------- Matugen & Wallust ----------
if [[ "$run_theme" == "1" ]]; then
  notify "Matugen" "Generating palette from image"
  matugen image "$used_wallpaper" -m dark || notify "Matugen" "failed (ignored)"
  notify "Wallust" "Applying scheme"
  wallust run "$used_wallpaper" || notify "Wallust" "failed (ignored)"
fi

# ---------- Bar/dock/notifications reload ----------
sleep 0.5
[ -x "$HOME/.config/waybar/launch.sh" ] && "$HOME/.config/waybar/launch.sh" || true
[ -x "$HOME/.config/nwg-dock-hyprland/launch.sh" ] && "$HOME/.config/nwg-dock-hyprland/launch.sh" &>/dev/null &
command -v pywalfox >/dev/null 2>&1 && pywalfox update || true
command -v swaync-client >/dev/null 2>&1 && swaync-client -rs || true

# ---------- Blur preview (met cache) ----------
blurred_cache="$generatedversions/blur-$blur-$effect-$wallpaperfilename.png"
if [[ -f "$blurred_cache" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
  notify "Blur" "Use cached preview"
else
  notify "Blur" "Generating preview ($blur)"
  magick "$used_wallpaper" -resize 75% "$blurredwallpaper"
  [[ "$blur" != "0x0" ]] && magick "$blurredwallpaper" -blur "$blur" "$blurredwallpaper"
  cp "$blurredwallpaper" "$blurred_cache"
fi
cp "$blurred_cache" "$blurredwallpaper"

# ---------- Rofi preview ----------
echo "* { current-image: url(\"$blurredwallpaper\", height); }" > "$rasifile"

# ---------- Vierkante preview ----------
notify "Square" "Generating square-cropped preview"
magick "$tmpwallpaper" -gravity Center -extent 1:1 "$squarewallpaper"
cp "$squarewallpaper" "$generatedversions/square-$wallpaperfilename.png"

