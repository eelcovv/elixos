#!/usr/bin/env bash
# Apply a wallpaper (optionally with effect), generate previews,
# and run theming tools. Uses 'notify' from helper-functions.sh.
set -euo pipefail

QUIET="${QUIET:-1}"  # 1 = quiet, 0 = notifications


# ---------- Helper + fallback notify ----------
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
    command -v logger >/dev/null 2>&1 && logger -t wallpaper -- "$title: $body" || true

    [ "$QUIET" = "1" ] && return 0
    command -v notify-send >/dev/null 2>&1 && notify-send "$title" "$body" || true
  }
fi

# ---------- Small wait for Hyprland to be ready ----------
_waitForHypr() {
  if command -v hyprctl >/dev/null 2>&1; then
    for _ in {1..20}; do hyprctl monitors -j >/dev/null 2>&1 && return 0; sleep 0.1; done
  else
    sleep 0.4
  fi
}

# ---------- Paths & settings ----------
settings_dir="$HOME/.config/hypr/settings"
effects_dir="$HOME/.config/hypr/effects/wallpaper"

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

# Cache toggle via presence file
use_cache=0
if [[ -f "$settings_dir/wallpaper_cache" ]]; then
  use_cache=1; notify "Wallpaper" "Cache enabled"
else
  notify "Wallpaper" "Cache disabled"
fi

# Blur value
blur="50x30"
[[ -f "$blurfile" ]] && blur="$(<"$blurfile")"

# ---------- Determine source wallpaper ----------
if [[ "${1:-}" == "" ]]; then
  wallpaper="$defaultwallpaper"
  [[ -f "$cachefile" ]] && wallpaper="$(<"$cachefile")"
else
  wallpaper="$1"
fi
[[ "$wallpaper" == ~* ]] && wallpaper="${wallpaper/#\~/$HOME}"

echo "$wallpaper" > "$cachefile"
tmpwallpaper="$wallpaper"
wallpaperfilename="$(basename "$wallpaper")"
notify "Wallpaper" "Source: $wallpaperfilename"

# ---------- Read & validate effect (always initialise!) ----------
effect="off"
if [[ -f "$effectfile" ]]; then
  effect="$(<"$effectfile")"
fi
# expand ~ if someone put it there
[[ "$effect" == ~* ]] && effect="${effect/#\~/$HOME}"
# only allow "off" or a file under effects_dir
if [[ "$effect" != "off" && ! -r "$effects_dir/$effect" ]]; then
  notify "Effect" "Invalid effect '$effect' → using off"
  effect="off"
fi

# ---------- Apply effect (if any) ----------
used_wallpaper="$wallpaper"
if [[ "$effect" != "off" ]]; then
  used_wallpaper="$generatedversions/$effect-$wallpaperfilename"
  if [[ -f "$used_wallpaper" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
    notify "Effect" "Using cached: $effect-$wallpaperfilename"
  else
    notify "Effect" "Generating: $effect-$wallpaperfilename"
    # shellcheck disable=SC1090
    source "$effects_dir/$effect"
  fi
else
  notify "Effect" "off"
fi

# ---------- Skip theme work if nothing changed ----------
state_key="$effect|$used_wallpaper"
run_theme=1
if [[ -f "$last_applied" ]] && [[ "$state_key" == "$(cat "$last_applied")" ]]; then
  notify "Wallpaper" "Same as last time → skip theming"
  run_theme=0
else
  echo "$state_key" > "$last_applied"
fi

# ---------- Set wallpaper via Waypaper/Hyprpaper ----------
_waitForHypr
notify "Wallpaper" "Setting: $used_wallpaper"
touch "$waypaperrunning"
waypaper --backend hyprpaper --wallpaper "$used_wallpaper" || notify "Wallpaper" "waypaper failed (ignored)"

# ---------- Matugen & Wallust ----------
if [[ "$run_theme" == "1" ]]; then
  notify "Matugen" "Generating palette"
  matugen image "$used_wallpaper" -m dark || notify "Matugen" "failed (ignored)"
  notify "Wallust" "Applying scheme"
  wallust run "$used_wallpaper" || notify "Wallust" "failed (ignored)"
fi

# ---------- UI reloads (no duplicates): only if theme changed ----------
if [[ "$run_theme" == "1" ]]; then
  # Waybar
  if systemctl --user is-active --quiet waybar.service 2>/dev/null; then
    pkill -USR2 waybar || true
  else
    if pgrep -x waybar >/dev/null 2>&1; then
      pkill -USR2 waybar || true
    elif [ -x "$HOME/.config/waybar/launch.sh" ]; then
      "$HOME/.config/waybar/launch.sh" || true
    fi
  fi
  # Dock
  if systemctl --user list-units --type=service --all 2>/dev/null | grep -q '^nwg-dock-hyprland\.service'; then
    systemctl --user try-restart nwg-dock-hyprland.service || true
  else
    if ! pgrep -f nwg-dock-hyprland >/dev/null 2>&1; then
      [ -x "$HOME/.config/nwg-dock-hyprland/launch.sh" ] && "$HOME/.config/nwg-dock-hyprland/launch.sh" &>/dev/null &
    fi
  fi
  command -v pywalfox >/dev/null 2>&1 && pywalfox update || true
  command -v swaync-client >/dev/null 2>&1 && swaync-client -rs || true
fi

# ---------- Blurred preview (cached) ----------
blurred_cache="$generatedversions/blur-$blur-$effect-$wallpaperfilename.png"
if [[ -f "$blurred_cache" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
  notify "Blur" "Using cached preview"
else
  notify "Blur" "Generating preview ($blur)"
  magick "$used_wallpaper" -resize 75% "$blurredwallpaper"
  [[ "$blur" != "0x0" ]] && magick "$blurredwallpaper" -blur "$blur" "$blurredwallpaper"
  cp "$blurredwallpaper" "$blurred_cache"
fi
cp "$blurred_cache" "$blurredwallpaper"

# ---------- Rofi preview ----------
echo "* { current-image: url(\"$blurredwallpaper\", height); }" > "$rasifile"

# ---------- Square-cropped preview ----------
notify "Square" "Generating square-cropped preview"
magick "$tmpwallpaper" -gravity Center -extent 1:1 "$squarewallpaper"
cp "$squarewallpaper" "$generatedversions/square-$wallpaperfilename.png"

