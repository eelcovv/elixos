#!/usr/bin/env bash
set -euo pipefail

BASE="$HOME/.config/waybar/themes"
CUR="$HOME/.config/waybar/current"

# Build list of "theme/variant" that contain a stylesheet
mapfile -t OPTIONS < <(
    find "$BASE" -mindepth 1 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -printf '%P\n' 2>/dev/null \
        | sed -E 's#/style(-custom)?\.css$##' \
        | sort -u
)

if [[ ${#OPTIONS[@]} -eq 0 ]]; then
    echo "No theme variants found under $BASE"
    exit 1
fi

# Pick via rofi/wofi/fzf (in die volgorde); val desnoods terug op eerste optie
pick_with_menu() {
    local prompt="Waybar theme"
    if command -v rofi >/dev/null 2>&1; then
        printf '%s\n' "${OPTIONS[@]}" | rofi -dmenu -p "$prompt" -i
    elif command -v wofi >/dev/null 2>&1; then
        printf '%s\n' "${OPTIONS[@]}" | wofi --dmenu -p "$prompt"
    elif command -v fzf >/dev/null 2>&1; then
        printf '%s\n' "${OPTIONS[@]}" | fzf --prompt "$prompt> "
    else
        # No menu available; default to the first option
        printf '%s\n' "${OPTIONS[0]}"
    fi
}

SEL="$(pick_with_menu || true)"
if [[ -z "${SEL:-}" ]]; then
    echo "No selection made."
    exit 1
fi

if [[ ! -d "$BASE/$SEL" ]]; then
    echo "Invalid selection: $SEL"
    exit 1
fi

ln -sfn "$BASE/$SEL" "$CUR"
systemctl --user restart waybar.service
notify-send "Waybar theme" "Applied: $SEL"

