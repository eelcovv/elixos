#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

WB_DIR="$HOME/.config/waybar"
THEMES_DIR="$WB_DIR/themes"

# Ensure the themes directory exists
if [[ ! -d "$THEMES_DIR" ]]; then
    notify-send "Waybar" "Themes dir not found: $THEMES_DIR"
    exit 1
fi

# Explicitly initialize arrays to satisfy `set -u`
declare -a paths=()
declare -a names=()

# Enumerate variants that have CSS, follow symlinks, skip assets
# Allow both single-level (e.g., themes/default/style.css)
# and nested (e.g., themes/ml4w/dark/style.css)
while IFS= read -r -d '' css_file; do
    variant_dir="$(dirname "$css_file")"
    case "$variant_dir" in
        *"/assets"/*) continue ;;
    esac
    rel="${variant_dir#"$THEMES_DIR"/}"   # -> "default" or "ml4w/dark" etc.

    # Optional friendly label from config.sh inside the variant dir
    label=""
    if [[ -f "$variant_dir/config.sh" ]]; then
        # shellcheck source=/dev/null
        source "$variant_dir/config.sh" || true
        label="${theme_name:-}"
    fi
    [[ -z "$label" ]] && label="$(printf "%s — %s" "${rel%%/*}" "${rel##*/}")"

    names+=("$label")
    paths+=("$rel")
done < <(find -L "$THEMES_DIR" -mindepth 1 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -print0)

# Handle empty result safely
if (( ${#paths[@]} == 0 )); then
    notify-send "Waybar" "No theme variants found under $THEMES_DIR"
    exit 1
fi

idx="$(printf "%s\n" "${names[@]}" | rofi -dmenu -i -no-show-icons -width 40 -p 'Waybar theme' -format i || true)"
[[ -z "${idx:-}" || ! "$idx" =~ ^[0-9]+$ ]] && exit 0

exec waybar-switch-theme "${paths[$idx]}"

