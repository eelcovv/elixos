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

# Base themes directory (allow optional override as first arg)
BASE="${1:-$HOME/.config/waybar/themes}"

# Local fallback scanner: find theme/variant dirs that contain style.css or style-custom.css
scan_variants_fallback() {
    local base="$1"
    [[ -d "$base" ]] || return 0
    find -L "$base" \
        -mindepth 2 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) \
        -printf '%h\n' | sed "s|^$base/||" | sort -u
}

# Collect options:
# 1) If helper provided list_theme_variants, use it
# 2) If empty, run the local fallback scanner
OPTIONS=()
if command -v list_theme_variants >/dev/null 2>&1; then
    mapfile -t OPTIONS < <(list_theme_variants "$BASE")
fi
if [[ ${#OPTIONS[@]} -eq 0 ]]; then
    mapfile -t OPTIONS < <(scan_variants_fallback "$BASE")
fi
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
        # No menu program; default to the first option
        printf '%s\n' "${OPTIONS[0]}"
    fi
}

SEL="$(pick_with_menu || true)"
if [[ -z "${SEL:-}" ]]; then
    echo "No selection made."
    exit 1
fi

# Ensure switch_theme exists (provided by the helper)
if ! command -v switch_theme >/dev/null 2>&1; then
    echo "switch_theme not found in helper: $FOUND" >&2
    exit 1
fi

switch_theme "$SEL"

# Optional terminal echo (switch_theme typically does notify-send already)
echo "Waybar theme applied: $SEL"

