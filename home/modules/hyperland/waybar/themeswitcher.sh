#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

WB_DIR="$HOME/.config/waybar"
THEMES_DIR="$WB_DIR/themes"
SETTINGS_FILE="$HOME/.config/hypr/settings/waybar-theme.sh"

# Ensure the settings directory exists
mkdir -p "$(dirname "$SETTINGS_FILE")"

declare -a paths names

# Find valid theme VARIANTS by looking for a CSS file in a subdirectory (>=2 levels deep).
# This avoids listing intermediate folders and "assets".
# We consider a directory a "variant" if it contains style.css or style-custom.css.
while IFS= read -r -d '' css_file; do
    variant_dir="$(dirname "$css_file")"                                       # .../themes/<theme>/<variant>
    rel="${variant_dir#"$THEMES_DIR"/}"                                        # -> <theme>/<variant>
    base="/${rel%%/*}"                                                         # -> /<theme>
    variant="/${rel}"                                                          # -> /<theme>/<variant>

    # Try to read a human-friendly theme name from config.sh in the VARIANT dir.
    label=""
    if [[ -f "$variant_dir/config.sh" ]]; then
        # shellcheck source=/dev/null
        source "$variant_dir/config.sh" || true
        label="${theme_name:-}"
    fi
    [[ -z "$label" ]] && label="$(printf "%s — %s" "${rel%%/*}" "${rel##*/}")"

    names+=("$label")
    paths+=("${base};${variant}")
done < <(find "$THEMES_DIR" -mindepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -print0)

# Abort if no variants found
if [[ ${#paths[@]} -eq 0 ]]; then
    notify-send "Waybar" "No theme variants found under $THEMES_DIR"
    exit 1
fi

# Show selection menu
choice_idx="$(printf "%s\n" "${names[@]}" | rofi -dmenu -i -no-show-icons -width 40 -p "Waybar theme" -format i || true)"
[[ -z "$choice_idx" || ! "$choice_idx" =~ ^[0-9]+$ ]] && exit 0

# Save selection in the format expected by your launch.sh: "/<theme>;/<theme>/<variant>"
selected="${paths[$choice_idx]}"
echo "$selected" > "$SETTINGS_FILE"
echo ":: Selected theme: $selected"

# Restart Waybar via your launcher
"$WB_DIR/launch.sh"

# Optional: recolor the desktop to match current wallpaper (if your pipeline exists)
if [[ -x "$HOME/.config/hypr/scripts/wallpaper.sh" ]]; then
    "$HOME/.config/hypr/scripts/wallpaper.sh"
fi

notify-send "Waybar Theme" "Applied: ${names[$choice_idx]}"

