
#!/usr/bin/env bash
set -euo pipefail

hypr_cache_folder="$HOME/.cache/hyprlock-assets"
default_wallpaper="$HOME/.config/wallpapers/default.png"  # png
cache_file="$hypr_cache_folder/current_wallpaper"
# ... rest unchanged ...


# -----------------------------------------------------
# Determine wallpaper to use
# -----------------------------------------------------

if [[ -f "$cache_file" ]]; then
    sed -i "s|~|$HOME|g" "$cache_file"
    wallpaper=$(<"$cache_file")
    if [[ ! -f "$wallpaper" ]]; then
        echo ":: Wallpaper $wallpaper does not exist. Using default."
        wallpaper="$default_wallpaper"
    else
        echo ":: Wallpaper $wallpaper exists"
    fi
else
    echo ":: $cache_file does not exist. Using default wallpaper."
    wallpaper="$default_wallpaper"
fi

# -----------------------------------------------------
# Set wallpaper
# -----------------------------------------------------

echo ":: Setting wallpaper with source image: $wallpaper"

# Add local waypaper if present
if [[ -x "$HOME/.local/bin/waypaper" ]]; then
    export PATH="$PATH:$HOME/.local/bin"
fi

waypaper --wallpaper "$wallpaper"

