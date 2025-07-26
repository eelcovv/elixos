#!/usr/bin/env bash

ml4w_cache_folder="$HOME/.cache/hyprlock-assets"

generated_versions="$ml4w_cache_folder/wallpaper-generated"

rm $generated_versions/*
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"
