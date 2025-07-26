#!/usr/bin/env bash
#                    __
#  _    _____ ___ __/ /  ___ _____
# | |/|/ / _ `/ // / _ \/ _ `/ __/
# |__,__/\_,_/\_, /_.__/\_,_/_/
#            /___/

set -euo pipefail

# -----------------------------------------------------
# Prevent duplicate launches: only the first parallel
# invocation proceeds; all others exit immediately.
# -----------------------------------------------------
exec 200>/tmp/waybar-launch.lock
flock -n 200 || exit 0

# -----------------------------------------------------
# Kill existing waybar instances
# -----------------------------------------------------
pkill -x waybar || true
sleep 0.5

# -----------------------------------------------------
# Default theme if nothing is defined
# -----------------------------------------------------
default_theme_folder="/modern"
default_theme_variant="/modern/light"
themestyle="${default_theme_folder};${default_theme_variant}"

# -----------------------------------------------------
# Determine current theme from theme config file
# -----------------------------------------------------
theme_config_file="$HOME/.config/hypr/settings/waybar-theme.sh"
if [[ -f "$theme_config_file" ]]; then
    themestyle="$(<"$theme_config_file")"
else
    echo "$themestyle" > "$theme_config_file"
fi

IFS=';' read -ra arrThemes <<< "$themestyle"
theme_folder="${arrThemes[0]}"
theme_variant="${arrThemes[1]}"

echo ":: Theme: $theme_folder"

# -----------------------------------------------------
# Check if required theme files exist
# -----------------------------------------------------
theme_base="$HOME/.config/waybar/themes"
if [[ ! -f "$theme_base${theme_variant}/style.css" ]]; then
    theme_folder="/fallback"
    theme_variant="/fallback/light"
fi

# -----------------------------------------------------
# Determine config and style files
# -----------------------------------------------------
config_file="config"
style_file="style.css"

if [[ -f "$theme_base${theme_folder}/config-custom" ]]; then
    config_file="config-custom"
fi

if [[ -f "$theme_base${theme_variant}/style-custom.css" ]]; then
    style_file="style-custom.css"
fi

# -----------------------------------------------------
# Start waybar unless explicitly disabled
# -----------------------------------------------------
if [[ ! -f "$HOME/.config/hypr/settings/waybar-disabled" ]]; then
    waybar -c "$theme_base${theme_folder}/$config_file" \
           -s "$theme_base${theme_variant}/$style_file" &
else
    echo ":: Waybar disabled"
fi

# flock wordt automatisch vrijgegeven bij exit

