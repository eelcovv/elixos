#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/.config/wallpapers"
REPO_URL="https://github.com/eelcovv/wallpaper"
TMP_DIR="$(mktemp -d)"

echo "📥 Downloading wallpapers from $REPO_URL..."

# clone repo shallow
git clone --depth=1 "$REPO_URL" "$TMP_DIR"

mkdir -p "$WALLPAPER_DIR"
find "$TMP_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.webp" \) -exec cp {} "$WALLPAPER_DIR/" \;

echo "✅ Wallpapers downloaded to $WALLPAPER_DIR"

# cleanup
rm -rf "$TMP_DIR"
