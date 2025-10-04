#!/usr/bin/env bash
# Apply a wallpaper, optional effect, then theming.
# English comments inside the code block.
set -euo pipefail

: "${QUIET:=0}"

# --- single-run lock ---
lockfile="/tmp/wallpaper.sh.lock"
exec 99>"$lockfile"
flock -n 99 || exit 0

# Helper notify
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
    if [[ "$QUIET" = "0" ]] && command -v notify-send >/dev/null 2>&1; then
      notify-send --hint=string:x-canonical-private-synchronous:wallpaper "$title" "$body" || true
    fi
  }
fi

# Small Hypr wait
_waitForHypr() {
  if command -v hyprctl >/dev/null 2>&1; then
    for _ in {1..20}; do hyprctl monitors -j >/dev/null 2>&1 && return 0; sleep 0.1; done
  else
    sleep 0.4
  fi
}

# ---------- Paths & settings ----------
settings_dir="$HOME/.config/hypr/settings"
effects_dir="$HOME/.config/hypr/effects/wallpaper"  # effect scripts live here

hypr_cache_folder="$HOME/.cache/hyprlock-assets"
mkdir -p "$hypr_cache_folder"
generatedversions="$hypr_cache_folder/wallpaper-generated"
mkdir -p "$generatedversions"

force_generate=0
cachefile="$hypr_cache_folder/current_wallpaper"
last_applied="$hypr_cache_folder/last_applied"
blurredwallpaper="$hypr_cache_folder/blurred_wallpaper.png"
squarewallpaper="$hypr_cache_folder/square_wallpaper.png"
rasifile="$hypr_cache_folder/current_wallpaper.rasi"

blurfile="$settings_dir/blur.sh"
effectconf="$settings_dir/effect.conf"
defaultwallpaper="$HOME/.config/wallpapers/default.png"

# Cache toggle
use_cache=0
if [[ -f "$settings_dir/wallpaper_cache" ]]; then
  use_cache=1; notify "Wallpaper" "Cache enabled"
else
  notify "Wallpaper" "Cache disabled"
fi

# Blur value
blur="50x30"
[[ -f "$blurfile" ]] && blur="$(<"$blurfile")"

# ---------- CLI: allow explicit --image/--effect ----------
IMG=""
EFFECT="${WALLPAPER_EFFECT:-}"  # env override optional

while [[ $# -gt 0 ]]; do
  case "$1" in
    --image)   IMG="$2"; shift 2 ;;
    --effect)  EFFECT="$2"; shift 2 ;;
    --verbose) QUIET="0"; shift ;;
    -h|--help)
      echo "Usage: $(basename "$0") --image /abs/path [--effect KEYWORD] [--verbose]"; exit 2 ;;
    *)  # Backward-compatible: single arg is image path
      [[ -z "$IMG" ]] && IMG="$1" || true; shift ;;
  esac
done

# ---------- Determine source wallpaper ----------
if [[ -z "${IMG:-}" ]]; then
  wallpaper="$defaultwallpaper"
  [[ -f "$cachefile" ]] && wallpaper="$(<"$cachefile")"
else
  wallpaper="$IMG"
fi
[[ "$wallpaper" == ~* ]] && wallpaper="${wallpaper/#\~/$HOME}"
echo "$wallpaper" > "$cachefile"
tmpwallpaper="$wallpaper"
wallpaperfilename="$(basename "$wallpaper")"
notify "Wallpaper" "Source: $wallpaperfilename"

# ---------- Determine effect keyword safely ----------
# Priority: CLI --effect > env WALLPAPER_EFFECT > effect.conf > "off"
if [[ -z "$EFFECT" && -r "$effectconf" ]]; then
  EFFECT="$(tr -d '\r' < "$effectconf" | awk 'NF{print $1; exit}')"
fi
EFFECT="${EFFECT:-off}"

# Accept any readable effect script; 'off'/'none' are special
if [[ "$EFFECT" != "off" && "$EFFECT" != "none" ]]; then
  if [[ ! -r "$effects_dir/$EFFECT" ]]; then
    notify "Effect" "Invalid effect '$EFFECT' → using off"
    EFFECT="off"
  fi
fi

# ---------- Apply effect (by keyword → source script) ----------
used_wallpaper="$wallpaper"
if [[ "$EFFECT" != "off" && "$EFFECT" != "none" ]]; then
  candidate="$effects_dir/$EFFECT"
  used_wallpaper="$generatedversions/$EFFECT-$wallpaperfilename"
  if [[ -f "$used_wallpaper" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
    notify "Effect" "Using cached: $EFFECT-$wallpaperfilename"
  else
    notify "Effect" "Generating: $EFFECT-$wallpaperfilename"
    # shellcheck disable=SC1090
    source "$candidate"
  fi
else
  notify "Effect" "off"
fi

# ---------- Skip theme work if nothing changed ----------
state_key="$EFFECT|$used_wallpaper"
run_theme=1
if [[ -f "$last_applied" ]] && [[ "$state_key" == "$(cat "$last_applied")" ]]; then
  notify "Wallpaper" "Same as last time → skip theming"
  run_theme=0
else
  echo "$state_key" > "$last_applied"
fi

# ---------- Set wallpaper ----------
if [[ "${WALLPAPER_ALREADY_SET:-0}" != "1" ]]; then
  _waitForHypr
  notify "Wallpaper" "Setting: $used_wallpaper"
  if command -v waypaper >/dev/null 2>&1; then
    waypaper --backend hyprpaper --wallpaper "$used_wallpaper" >/dev/null 2>&1 || true
  fi
fi

# ---------- Matugen & Wallust ----------
if [[ "$run_theme" == "1" ]]; then
  notify "Matugen" "Generating palette"
  matugen image "$used_wallpaper" -m dark || notify "Matugen" "failed (ignored)"
  notify "Wallust" "Applying scheme"
  wallust run "$used_wallpaper" || notify "Wallust" "failed (ignored)"
fi

# ---------- UI reloads ----------
if [[ "$run_theme" == "1" ]]; then
  if systemctl --user is-active --quiet waybar.service 2>/dev/null; then
    pkill -USR2 waybar || true
  else
    if pgrep -x waybar >/dev/null 2>&1; then
      pkill -USR2 waybar || true
    elif [ -x "$HOME/.config/waybar/launch.sh" ]; then
      "$HOME/.config/waybar/launch.sh" || true
    fi
  fi
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

# ---------- Previews ----------
blurred_cache="$generatedversions/blur-$blur-$EFFECT-$wallpaperfilename.png"
if [[ -f "$blurred_cache" && "$force_generate" == "0" && "$use_cache" == "1" ]]; then
  notify "Blur" "Using cached preview"
else
  notify "Blur" "Generating preview ($blur)"
  magick "$used_wallpaper" -resize 75% "$blurredwallpaper"
  [[ "$blur" != "0x0" ]] && magick "$blurredwallpaper" -blur "$blur" "$blurredwallpaper"
  cp "$blurredwallpaper" "$blurred_cache"
fi
cp "$blurred_cache" "$blurredwallpaper"

echo "* { current-image: url(\"$blurredwallpaper\", height); }" > "$rasifile"

notify "Square" "Generating square-cropped preview"
magick "$tmpwallpaper" -gravity Center -extent 1:1 "$squarewallpaper"
cp "$squarewallpaper" "$generatedversions/square-$wallpaperfilename.png"

