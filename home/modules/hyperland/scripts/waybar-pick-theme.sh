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

# Ensure there is exactly ONE Waybar:
# 1) stop any lingering systemd user service
systemctl --user stop waybar.service 2>/dev/null || true

# 2) kill any running Waybar processes (name or full cmdline)
pkill -x waybar 2>/dev/null || true
pkill -f '(^|/| )waybar( |$)' 2>/dev/null || true
sleep 0.3

# 3) start a single instance
waybar >/dev/null 2>&1 & disown

notify-send "Waybar theme" "Applied: $THEME"

