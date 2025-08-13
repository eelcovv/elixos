#!/usr/bin/env bash
set -euo pipefail
THEME="${1:-}"
if [[ -z "$THEME" ]]; then
    echo "Usage: waybar-switch-theme <theme-path> (e.g., ml4w/dark)"
    exit 2
fi

HOST="$(hostname)"
env HOME_THEME="$THEME" home-manager switch --flake ".#eelco@$HOST"
systemctl --user restart waybar.service
notify-send "Waybar theme" "Applied: $THEME"

