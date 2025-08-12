#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# Usage: waybar-switch-theme ml4w/dark
THEME="${1:-}"
if [[ -z "$THEME" ]]; then
    echo "Usage: waybar-switch-theme <theme-path> (e.g., ml4w/dark)"
    exit 2
fi

THEMES_DIR="$HOME/.config/waybar/themes"
if [[ ! -d "$THEMES_DIR/$THEME" ]]; then
    echo "Unknown theme variant: $THEME"
    exit 1
fi
if [[ ! -f "$THEMES_DIR/$THEME/style.css" && ! -f "$THEMES_DIR/$THEME/style-custom.css" ]]; then
    echo "Theme '$THEME' has no style.css"
    exit 1
fi

echo ":: Switching HOME_THEME=$THEME via Home Manager..."
HOST="$(hostname)"
env HOME_THEME="$THEME" home-manager switch --flake ".#eelco@$HOST"

# Reload the single Waybar instance if present; do NOT spawn a new one
if pgrep -x waybar >/dev/null; then
    pkill -USR2 waybar || true
else
    notify-send "Waybar" "No running instance to reload. Start it once via Hypr autostart or run: waybar &"
fi

notify-send "Waybar theme" "Applied: $THEME"

