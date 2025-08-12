#!/usr/bin/env bash
#  _              _     _           _ _
# | | _____ _   _| |__ (_)_ __   __| (_)_ __   __ _ ___
# | |/ / _ \ | | | '_ \| | '_ \ / _` | | '_ \ / _` / __|
# |   <  __/ |_| | |_) | | | | | (_| | | | | | (_| \__ \
# |_|\_\___|\__, |_.__/|_|_| |_|\__,_|_|_| |_|\__, |___/
#           |___/                             |___/
#
# -----------------------------------------------------
# Show Hyprland keybindings with Rofi
# -----------------------------------------------------

# Resolve the path to the active keybinding file
conf_ref="$HOME/.config/hypr/conf/keybinding.conf"
if [[ ! -f "$conf_ref" ]]; then
  echo "⚠️  Keybinding config reference not found: $conf_ref"
  exit 1
fi

config_file=$(<"$conf_ref")
config_file="${config_file//source = ~//home/$USER}"

if [[ ! -f "$config_file" ]]; then
  echo "⚠️  Actual keybinding file not found: $config_file"
  exit 1
fi

echo "Reading from: $config_file"

# Extract keybindings in a readable format
keybinds=$(awk -F'[=#]' '
  $1 ~ /^bind/ {
    gsub(/\$mainMod/, "SUPER", $0)
    gsub(/^bind[[:space:]]*=+[[:space:]]*/, "", $0)
    split($1, kbarr, ",")
    printf "%-15s → %s\n", kbarr[1] " + " kbarr[2], $2
  }
' "$config_file")

# Pick rofi theme from environment or fallback
rofi_theme="${ROFI_THEME:-$HOME/.config/rofi/themes/default/config.rasi}"

# Display menu
sleep 0.2
rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" -config "$rofi_theme" <<<"$keybinds"

