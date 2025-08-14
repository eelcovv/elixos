set -euo pipefail
hypr_cache_folder="$HOME/.cache/hyprlock-assets"
generated_versions="$hypr_cache_folder/wallpaper-generated"
mkdir -p "$generated_versions"
rm -f -- "$generated_versions"/* 2>/dev/null || true
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"

