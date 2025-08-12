#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

# -----------------------------------------------------
# Single-instance guard: only one launcher runs at once
# -----------------------------------------------------
exec 200>/tmp/waybar-launch.lock
flock -n 200 || exit 0

# -----------------------------------------------------
# Stop existing Waybar instances (if any)
# -----------------------------------------------------
pkill -x waybar || true
sleep 0.5

# -----------------------------------------------------
# Default theme (folder;variant) if no selection exists
# Matches the format written by themeswitcher.sh
# Example: "/ml4w;/ml4w/dark"
# -----------------------------------------------------
default_theme_folder="/modern"
default_theme_variant="/modern/light"
themestyle="${default_theme_folder};${default_theme_variant}"

# -----------------------------------------------------
# Read current theme selection from settings file
# If missing, initialize it with defaults
# -----------------------------------------------------
theme_config_file="$HOME/.config/hypr/settings/waybar-theme.sh"
if [[ -f "$theme_config_file" ]]; then
    themestyle="$(<"$theme_config_file")"
else
    mkdir -p "$(dirname "$theme_config_file")"
    echo "$themestyle" > "$theme_config_file"
fi

IFS=';' read -r theme_folder theme_variant <<< "$themestyle"
: "${theme_folder:=/modern}"
: "${theme_variant:=/modern/light}"

theme_base="$HOME/.config/waybar/themes"
echo ":: Waybar theme folder: $theme_folder"
echo ":: Waybar theme variant: $theme_variant"

# -----------------------------------------------------
# Validate required files for the selected variant
# If the variant style is missing, fall back safely
# -----------------------------------------------------
if [[ ! -f "$theme_base${theme_variant}/style.css" && ! -f "$theme_base${theme_variant}/style-custom.css" ]]; then
    echo ":: Variant style not found, falling back to /fallback/light"
    theme_folder="/fallback"
    theme_variant="/fallback/light"
fi

# -----------------------------------------------------
# Resolve config file for the theme folder
# Priority: config-custom > config.jsonc > config.json > config
# -----------------------------------------------------
config_file=""
if   [[ -f "$theme_base${theme_folder}/config-custom" ]];   then config_file="config-custom"
elif [[ -f "$theme_base${theme_folder}/config.jsonc" ]];    then config_file="config.jsonc"
elif [[ -f "$theme_base${theme_folder}/config.json" ]];     then config_file="config.json"
elif [[ -f "$theme_base${theme_folder}/config" ]];          then config_file="config"
else
    echo ":: No config found in $theme_base${theme_folder}, falling back to /fallback"
    theme_folder="/fallback"
    if   [[ -f "$theme_base${theme_folder}/config.jsonc" ]]; then config_file="config.jsonc"
    elif [[ -f "$theme_base${theme_folder}/config.json" ]];  then config_file="config.json"
    else                                                      config_file="config"
    fi
fi

# -----------------------------------------------------
# Resolve style file for the variant
# Priority: style-custom.css > style.css
# -----------------------------------------------------
style_file=""
if   [[ -f "$theme_base${theme_variant}/style-custom.css" ]]; then style_file="style-custom.css"
else                                                           style_file="style.css"
fi

# -----------------------------------------------------
# Start Waybar unless a disable flag file exists
# -----------------------------------------------------
if [[ ! -f "$HOME/.config/hypr/settings/waybar-disabled" ]]; then
    waybar  -c "$theme_base${theme_folder}/$config_file" \
            -s "$theme_base${theme_variant}/$style_file" &
else
    echo ":: Waybar disabled (flag file present)"
fi

# flock on FD 200 is released automatically on script exit

