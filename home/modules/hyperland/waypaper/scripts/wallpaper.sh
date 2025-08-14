#!/usr/bin/env bash
set -euo pipefail

# Shared helper
source "$HOME/.config/hypr/scripts/helper-functions.sh"

# Wallpaper cache control
use_cache=0
if [[ -f "$HOME/.config/hypr/settings/wallpaper_cache" ]]; then
  use_cache=1; _writeLog "Using Wallpaper Cache"
else
  _writeLog "Wallpaper Cache disabled"
fi

# Prepare folders
hypr_cache_folder="$HOME/.cache/hyprlock-assets"
mkdir -p "$hypr_cache_folder"
generatedversions="$hypr_cache_folder/wallpaper-generated"
mkdir -p "$generatedversions"
waypaperrunning="$hypr_cache_folder/waypaper-running"
[[ -f "$waypaperrunning" ]] && rm "$waypaperrunning" && exit

# Defaults and paths
force_generate=0
cachefile="$hypr_cache_folder/current_wallpaper"
blurredwallpaper="$hypr_cache_folder/blurred_wallpaper.png"
squarewallpaper="$hypr_cache_folder/square_wallpaper.png"
rasifile="$hypr_cache_folder/current_wallpaper.rasi"
blurfile="$HOME/.config/hypr/settings/blur.sh"
defaultwallpaper="$HOME/.config/wallpapers/default.png"  # <— png
wallpapereffect="$HOME/.config/hypr/settings/wallpaper-effect.sh"
blur="50x30"
[[ -f "$blurfile" ]] && blur="$(<"$blurfile")"

# Determine wallpaper
if [[ "${1:-}" == "" ]]; then
  wallpaper="${defaultwallpaper}"
  [[ -f "$cachefile" ]] && wallpaper="$(<"$cachefile")"
else
  wallpaper="$1"
fi

used_wallpaper="$wallpaper"
_writeLog "Setting wallpaper with source image $wallpaper"
tmpwallpaper="$wallpaper"

echo "$wallpaper" > "$cachefile"
wallpaperfilename="$(basename "$wallpaper")"
_writeLog "Wallpaper Filename: $wallpaperfilename"

# Wallpaper effects
effect="off"
if [[ -f "$wallpapereffect" ]]; then
  effect="$(<"$wallpapereffect")"
  if [[ "$effect" != "off" ]]; then
    used_wallpaper="$generatedversions/$effect-$wallpaperfilename"
    if [[ -f "$used_wallpaper" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
      _writeLog "Use cached wallpaper $effect-$wallpaperfilename"
    else
      _writeLog "Generate cached wallpaper $effect-$wallpaperfilename with effect $effect"
      notify-send --replace-id=1 "Using wallpaper effect $effect..." "with image $wallpaperfilename" -h int:value:33
      source "$HOME/.config/hypr/effects/wallpaper/$effect"
    fi
    _writeLog "Setting wallpaper with $used_wallpaper"
    touch "$waypaperrunning"
    waypaper --wallpaper "$used_wallpaper"
  else
    _writeLog "Wallpaper effect is set to off"
  fi
fi

# Matugen & Wallust (use PATH)
_writeLog "Execute matugen with $used_wallpaper"
matugen image "$used_wallpaper" -m dark || _writeLog "matugen failed (ignored)"

_writeLog "Execute wallust with $used_wallpaper"
wallust run "$used_wallpaper" || _writeLog "wallust failed (ignored)"

# Reload bar/dock/notifications (best effort)
sleep 1
[ -x "$HOME/.config/waybar/launch.sh" ] && "$HOME/.config/waybar/launch.sh" || true
[ -x "$HOME/.config/nwg-dock-hyprland/launch.sh" ] && "$HOME/.config/nwg-dock-hyprland/launch.sh" &>/dev/null &

command -v pywalfox >/dev/null 2>&1 && pywalfox update || true
command -v swaync-client >/dev/null 2>&1 && swaync-client -rs || true

# Generate blurred wallpaper
blurred_cache="$generatedversions/blur-$blur-$effect-$wallpaperfilename.png"
if [[ -f "$blurred_cache" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
  _writeLog "Use cached blurred wallpaper $blurred_cache"
else
  _writeLog "Generating blurred wallpaper with blur $blur"
  magick "$used_wallpaper" -resize 75% "$blurredwallpaper"
  [[ "$blur" != "0x0" ]] && magick "$blurredwallpaper" -blur "$blur" "$blurredwallpaper"
  cp "$blurredwallpaper" "$blurred_cache"
fi
cp "$blurred_cache" "$blurredwallpaper"

# .rasi preview for rofi
echo "* { current-image: url(\"$blurredwallpaper\", height); }" > "$rasifile"

# Square-cropped wallpaper
_writeLog "Generating square-cropped wallpaper $squarewallpaper"
magick "$tmpwallpaper" -gravity Center -extent 1:1 "$squarewallpaper"
cp "$squarewallpaper" "$generatedversions/square-$wallpaperfilename.png"

