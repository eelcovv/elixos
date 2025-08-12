#!/usr/bin/env bash

hypr_cache_folder="$HOME/.cache/hyprlock-assets"

generated_versions="$hypr_cache_folder/wallpaper-generated"

rm $generated_versions/*
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"
