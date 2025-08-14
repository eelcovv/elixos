#!/usr/bin/env bash
# Pure switch: update ~/.config/waybar/current symlink and restart user service.
# shellcheck shell=bash
set -euo pipefail

# Prefer installed helper; fall back to repo-local during development.
# Tell ShellCheck where to find it in-repo:
# shellcheck source=./helper-functions.sh
HELPER_CANDIDATES=(
    "$HOME/.local/lib/waybar-theme/helper-functions.sh"
    "${XDG_DATA_HOME:-$HOME/.local/share}/waybar-theme/helper-functions.sh"
    "$(dirname -- "${BASH_SOURCE[0]}")/helper-functions.sh"
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

