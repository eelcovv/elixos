#!/usr/bin/env bash
# Pure switch: update ~/.config/waybar/current symlink and restart user service.
# shellcheck shell=bash
set -euo pipefail

HELPER_CANDIDATES=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/helper-functions.sh" # geïnstalleerde helper
    "$(dirname -- "${BASH_SOURCE[0]}")/helper-functions.sh" # dev-fallback naast het script
)
FOUND=""
for f in "${HELPER_CANDIDATES[@]}"; do
    if [[ -r "$f" ]]; then
        # shellcheck disable=SC1090
        . "$f"
        FOUND="$f"
        break
    fi
done
if [[ -z "$FOUND" ]]; then
    echo "helper-functions.sh not found. Tried: ${HELPER_CANDIDATES[*]}" >&2
    exit 1
fi

THEME="${1:-}"  # e.g. ml4w/light
if [[ -z "$THEME" ]]; then
    echo "Usage: waybar-switch-theme <theme-path>  (e.g., ml4w/light)"
    exit 2
fi

switch_theme "$THEME"

