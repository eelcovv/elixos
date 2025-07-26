#!/usr/bin/env bash
#  _____ _                                       _ _       _
# |_   _| |__   ___ _ __ ___   ___  _____      _(_) |_ ___| |__   ___ _ __
#   | | | '_ \ / _ \ '_ ` _ \ / _ \/ __\ \ /\ / / | __/ __| '_ \ / _ \ '__|
#   | | | | | |  __/ | | | | |  __/\__ \\ V  V /| | || (__| | | |  __/ |
#   |_| |_| |_|\___|_| |_| |_|\___||___/ \_/\_/ |_|\__\___|_| |_|\___|_|

# by Stephan Raabe (2024)
# -----------------------------------------------------

set -euo pipefail

# Default theme folder
themes_path="$HOME/.config/waybar/themes"
settings_file="$HOME/.config/hypr/settings/waybar-theme.sh"

# Create settings dir if missing
mkdir -p "$(dirname "$settings_file")"

# Initialize arrays
declare -a listThemes
declare -a listNames

# Read theme folders
while IFS= read -r -d '' theme_dir; do
    # Skip "assets" and root
    [[ "$theme_dir" == "$themes_path" || "$theme_dir" == "$themes_path/assets" ]] && continue

    # Only include leaf directories (no subfolders)
    if [[ "$(find "$theme_dir" -mindepth 1 -type d | wc -l)" == "0" ]]; then
        rel_path="${theme_dir#$themes_path}"
        theme_id="${rel_path#/}" # remove leading slash

        theme_entry="/$theme_id;$rel_path"
        config_file="$theme_dir/config.sh"

        if [[ -f "$config_file" ]]; then
            # shellcheck disable=SC1090
            source "$config_file"
            listNames+=("$theme_name")
        else
            listNames+=("$theme_id;$rel_path")
        fi

        listThemes+=("$theme_entry")
    fi
done < <(find "$themes_path" -mindepth 1 -maxdepth 1 -type d -print0)

# Exit if no themes found
if [[ "${#listThemes[@]}" -eq 0 ]]; then
    notify-send "No themes found" "No Waybar themes detected in $themes_path"
    exit 1
fi

# Show rofi menu
menu=$(printf "%s\n" "${listNames[@]}")
choice=$(echo -e "$menu" | rofi -dmenu -i -no-show-icons -width 30 -p "Themes" -format i -config ~/.config/rofi/config-themes.rasi)

# Apply theme
if [[ -n "$choice" && "$choice" =~ ^[0-9]+$ ]]; then
    selected="${listThemes[$choice]}"
    echo "$selected" > "$settings_file"
    echo ":: Selected theme: $selected"
    "$HOME/.config/waybar/launch.sh"
else
    echo ":: No theme selected"
fi

