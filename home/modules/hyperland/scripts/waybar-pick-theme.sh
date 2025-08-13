#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

THEME="${1:-}"
if [[ -z "$THEME" ]]; then
    echo "Usage: waybar-pick-theme <theme-path> (e.g., ml4w/dark)"
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

systemctl --user restart waybar.service

notify-send "Waybar theme" "Applied: $THEME"

