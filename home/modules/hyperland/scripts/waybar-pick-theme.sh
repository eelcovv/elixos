#!/usr/bin/env bash
# Two-step picker: pick theme family, then variant; delegate to switch_theme.
# Filters out non-themes like "assets".
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
        head -n1
    fi
}

# --- 1) Build filtered list of families (skip non-themes like "assets") ---
FAMILIES=()
while IFS= read -r -d '' famdir; do
    fam="$(basename "$famdir")"
    # skip hidden dirs
    [[ "$fam" == .* ]] && continue

    has_root_style=0
    [[ -f "$famdir/style.css" || -f "$famdir/style-custom.css" ]] && has_root_style=1

    has_variant=0
    # scan one level of subdirs for style.css / style-custom.css
    for vdir in "$famdir"/*/ ; do
        [[ -d "$vdir" ]] || continue
        if [[ -f "$vdir/style.css" || -f "$vdir/style-custom.css" ]]; then
            has_variant=1
            break
        fi
    done

    if (( has_root_style == 1 || has_variant == 1 )); then
        FAMILIES+=("$fam")
    fi
done < <(find -L "$BASE" -mindepth 1 -maxdepth 1 -type d -print0)

if [[ ${#FAMILIES[@]} -eq 0 ]]; then
    echo "No theme families with styles found under $BASE"
    exit 1
fi
IFS=$'\n' FAMILIES=( $(printf '%s\n' "${FAMILIES[@]}" | sort -u) ); unset IFS

SEL_FAMILY="$(printf '%s\n' "${FAMILIES[@]}" | menu_pick "Waybar theme")"
[[ -n "${SEL_FAMILY:-}" ]] || { echo "No selection made."; exit 1; }

FAM_DIR="$BASE/$SEL_FAMILY"

# --- 2) Variants for this family (subdirs that contain style.css or style-custom.css) ---
FILTERED=()
for vdir in "$FAM_DIR"/*/ ; do
    [[ -d "$vdir" ]] || continue
    if [[ -f "$vdir/style.css" || -f "$vdir/style-custom.css" ]]; then
        FILTERED+=( "$(basename "$vdir")" )
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

# --- 3) Switch ---
switch_theme "$SEL_FAMILY/$SEL_VARIANT"

