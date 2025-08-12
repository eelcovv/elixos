#!/usr/bin/env bash
set -euo pipefail

WB_DIR="$HOME/.config/waybar"
THEMES_DIR="$WB_DIR/themes"
SETTINGS_FILE="$HOME/.config/hypr/settings/waybar-theme.sh"

# Ensure the settings directory exists
mkdir -p "$(dirname "$SETTINGS_FILE")"

declare -a paths names

# Find all theme variants (leaf directories at least 2 levels deep), skip "assets"
while IFS= read -r -d '' variant_dir; do
  # Example: /home/user/.config/waybar/themes/ml4w/light
  rel="${variant_dir#$THEMES_DIR/}"        # -> ml4w/light
  base="/${rel%%/*}"                       # -> /ml4w
  variant="/${rel}"                        # -> /ml4w/light

  # Try to read a human-friendly theme name from config.sh in the variant directory
  label=""
  if [[ -f "$variant_dir/config.sh" ]]; then
    # shellcheck disable=SC1090
    source "$variant_dir/config.sh" || true
    label="${theme_name:-}"
  fi
  [[ -z "$label" ]] && label="$(printf "%s — %s" "${rel%%/*}" "${rel##*/}")"

  names+=("$label")
  paths+=("${base};${variant}")
done < <(find "$THEMES_DIR" -mindepth 2 -type d -not -path '*/assets*' -print0)

# Abort if no variants found
if [[ ${#paths[@]} -eq 0 ]]; then
  notify-send "Waybar" "No theme variants found under $THEMES_DIR"
  exit 1
fi

# Show selection menu
choice_idx="$(printf "%s\n" "${names[@]}" | rofi -dmenu -i -no-show-icons -width 40 -p "Waybar theme" -format i || true)"
[[ -z "$choice_idx" || ! "$choice_idx" =~ ^[0-9]+$ ]] && exit 0

# Save selection
selected="${paths[$choice_idx]}"
echo "$selected" > "$SETTINGS_FILE"
echo ":: Selected theme: $selected"

# Restart Waybar via your launcher
"$WB_DIR/launch.sh"

# Optional: also recolor based on the current wallpaper
if [[ -x "$HOME/.config/hypr/scripts/wallpaper.sh" ]]; then
  "$HOME/.config/hypr/scripts/wallpaper.sh"
fi

notify-send "Waybar Theme" "Applied: ${names[$choice_idx]}"

