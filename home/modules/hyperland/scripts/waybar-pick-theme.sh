#!/usr/bin/env bash
# Two-step picker: pick theme family, then variant; delegate to switch_theme.
# shellcheck shell=bash
set -euo pipefail

# Prefer installed helper; fall back to repo-local during development.
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
[[ -d "$BASE" ]] || { echo "No themes dir at $BASE"; exit 1; }

# --- helpers for menu ---
menu_pick() {
    # args: prompt
    local prompt="$1"
    if command -v rofi >/dev/null 2>&1; then
        rofi -dmenu -p "$prompt" -i
    elif command -v wofi >/dev/null 2>&1; then
        wofi --dmenu -p "$prompt"
    elif command -v fzf >/dev/null 2>&1; then
        fzf --prompt "$prompt> "
    else
        # dumb fallback: pick the first line
        head -n1
    fi
}

# 1) families = alle directe submappen
mapfile -t FAMILIES < <(find -L "$BASE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
if [[ ${#FAMILIES[@]} -eq 0 ]]; then
    echo "No theme families found under $BASE"
    exit 1
fi

SEL_FAMILY="$(printf '%s\n' "${FAMILIES[@]}" | menu_pick "Waybar theme")"
[[ -n "${SEL_FAMILY:-}" ]] || { echo "No selection made."; exit 1; }

FAM_DIR="$BASE/$SEL_FAMILY"

# 2) varianten = submappen met style.css of style-custom.css
VARIANTS=()
while IFS= read -r -d '' d; do
    b="$(basename "$d")"
    VARIANTS+=("$b")
done < <(find -L "$FAM_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

# filter op aanwezigheid style.css / style-custom.css
FILTERED=()
for v in "${VARIANTS[@]}"; do
    if [[ -f "$FAM_DIR/$v/style.css" || -f "$FAM_DIR/$v/style-custom.css" ]]; then
        FILTERED+=("$v")
    fi
done

if [[ ${#FILTERED[@]} -eq 0 ]]; then
    # geen sub-varianten → gebruik root (family) als “variant” als daar style.css(-custom) staat
    if [[ -f "$FAM_DIR/style.css" || -f "$FAM_DIR/style-custom.css" ]]; then
        switch_theme "$SEL_FAMILY"
        exit 0
    else
        echo "Theme '$SEL_FAMILY' has no variants and no root style.css"
        exit 1
    fi
fi

SEL_VARIANT="$(printf '%s\n' "${FILTERED[@]}" | menu_pick "$SEL_FAMILY variant")"
[[ -n "${SEL_VARIANT:-}" ]] || { echo "No selection made."; exit 1; }

# 3) switch
switch_theme "$SEL_FAMILY/$SEL_VARIANT"

