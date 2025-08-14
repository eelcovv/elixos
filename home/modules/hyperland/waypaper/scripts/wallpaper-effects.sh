#!/usr/bin/env bash
# __        ______    _____  __  __           _
# \ \      / /  _ \  | ____|/ _|/ _| ___  ___| |_ ___
#  \ \ /\ / /| |_) | |  _| | |_| |_ / _ \/ __| __/ __|
#   \ V  V / |  __/  | |___|  _|  _|  __/ (__| |_\__ \
#    \_/\_/  |_|     |_____|_| |_|  \___|\___|\__|___/
#

set -euo pipefail

hypr_cache_folder="$HOME/.cache/hyprlock-assets"
cache_file="$hypr_cache_folder/current_wallpaper"
effect_file="$HOME/.config/hypr/settings/wallpaper-effect.sh"
effects_dir="$HOME/.config/hypr/effects/wallpaper"
rofi_config="$HOME/.config/rofi/config.rasi"


if [[ "${1:-}" == "reload" ]]; then
    if [[ -f "$cache_file" ]]; then
        waypaper --wallpaper "$(cat "$cache_file")"
    else
        notify-send "Wallpaper Effect" "No cached wallpaper found."
        exit 1
    fi
else
    options="$(ls "$effects_dir")"$'\n'"off"
    choice=$(echo -e "$options" | rofi -dmenu -replace -config "$rofi_config" -i -no-show-icons -l 5 -width 30 -p "Hyprshade")

    if [[ -n "${choice:-}" ]]; then
        echo "$choice" > "$effect_file"
        notify-send "Changing Wallpaper Effect" "$choice"

        if [[ -f "$cache_file" ]]; then
            waypaper --wallpaper "$(cat "$cache_file")"
        else
            notify-send "Wallpaper Effect" "No cached wallpaper found."
            exit 1
        fi
    fi
fi

