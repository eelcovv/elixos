#!/usr/bin/env bash
set -euo pipefail

THEMES_DIR="$HOME/.config/waybar/themes"
SETTINGS_FILE="$HOME/.config/hypr/settings/current-theme"

mkdir -p "$(dirname "$SETTINGS_FILE")"

declare -a theme_paths
declare -a theme_names

# Zoek naar directories met config.sh
while IFS= read -r config_path; do
  theme_dir="$(dirname "$config_path")"
  rel_path="${theme_dir#$THEMES_DIR/}"

  # shellcheck source=/dev/null
  source "$config_path"

  theme_paths+=("$rel_path")
  theme_names+=("${theme_name:-$rel_path}")
done < <(find "$THEMES_DIR" -type f -name "config.sh")

if [[ ${#theme_paths[@]} -eq 0 ]]; then
  notify-send "Waybar Themeswitcher" "No themes found in $THEMES_DIR"
  exit 1
fi

# Toon rofi menu
choice=$(printf "%s\n" "${theme_names[@]}" | rofi -dmenu -i -no-show-icons -width 30 -p "Themes" -format i)

if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ ]]; then
  selected_path="${theme_paths[$choice]}"
  echo "HOME_THEME=$selected_path" > "$SETTINGS_FILE"
  notify-send "Waybar theme set to" "$selected_path"
  systemctl --user restart waybar.service || pkill -USR2 waybar
else
  echo ":: No theme selected"
fi
