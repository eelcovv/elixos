#!/usr/bin/env bash

wallpaper_dir="$HOME/.config/hypr/wallpapers"
automation_flag="$HOME/.cache/hyprlock-assets/wallpaper-automation"
interval_file="$HOME/.config/hypr/settings/wallpaper-automation.sh"

if [ ! -f "$interval_file" ]; then
    echo "60" > "$interval_file"
fi

sec=$(cat "$interval_file")

_setWallpaperRandomly() {
    waypaper --random
    echo ":: Next wallpaper in $sec seconds..."
    sleep "$sec"
    _setWallpaperRandomly
}

if [ ! -f "$automation_flag" ]; then
    touch "$automation_flag"
    notify-send "Wallpaper automation started" "Wallpaper will change every $sec seconds."
    _setWallpaperRandomly
else
    rm "$automation_flag"
    notify-send "Wallpaper automation stopped."
    pkill -f wallpaper-automation.sh
fi

