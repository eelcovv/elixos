#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Usage: waybar-switch-theme ml4w/dark
THEME="${1:-}"
if [[ -z "$THEME" ]]; then
    echo "Usage: waybar-switch-theme <theme-path> (e.g., ml4w/dark)"
    exit 2
fi

BASE="$HOME/.config/waybar/themes"
if [[ ! -d "$BASE/$THEME" ]]; then
    echo "Unknown theme variant: $THEME"
    exit 1
fi
if [[ ! -f "$BASE/$THEME/style.css" && ! -f "$BASE/$THEME/style-custom.css" ]]; then
    echo "Theme '$THEME' has no style.css"
    exit 1
fi

echo ":: Switching HOME_THEME=$THEME and rebuilding with Home Manager..."
HOST="$(hostname)"
env HOME_THEME="$THEME" home-manager switch --flake ".#eelco@$HOST"

# Reload Waybar without spawning duplicates
if pgrep -x waybar >/dev/null; then
    pkill -USR2 waybar || true
else
    waybar &
fi

notify-send "Waybar theme" "Applied: $THEME"
