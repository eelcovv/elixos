#!/usr/bin/env bash
# Interactive picker: choose a variant, then delegate to switch_theme.
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

BASE="$HOME/.config/waybar/themes"

mapfile -t OPTIONS < <(list_theme_variants "$BASE")
if [[ ${#OPTIONS[@]} -eq 0 ]]; then
    echo "No theme variants found under $BASE"
    exit 1
fi

pick_with_menu() {
    local prompt="Waybar theme"
    if command -v rofi >/dev/null 2>&1; then
        printf '%s\n' "${OPTIONS[@]}" | rofi -dmenu -p "$prompt" -i
    elif command -v wofi >/dev/null 2>&1; then
        printf '%s\n' "${OPTIONS[@]}" | wofi --dmenu -p "$prompt"
    elif command -v fzf >/dev/null 2>&1; then
        printf '%s\n' "${OPTIONS[@]}" | fzf --prompt "$prompt> "
    else
        printf '%s\n' "${OPTIONS[0]}"
    fi
}

SEL="$(pick_with_menu || true)"
if [[ -z "${SEL:-}" ]]; then
    echo "No selection made."
    exit 1
fi

switch_theme "$SEL"

