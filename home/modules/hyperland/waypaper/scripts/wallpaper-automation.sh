#!/usr/bin/env bash
set -euo pipefail
automation_flag="$HOME/.cache/hyprlock-assets/wallpaper-automation"
interval_file="$HOME/.config/hypr/settings/wallpaper-automation.sh"

mkdir -p "$(dirname "$automation_flag")" "$(dirname "$interval_file")"
[[ -f "$interval_file" ]] || echo "60" > "$interval_file"
sec=$(<"$interval_file")

_loop() {
  waypaper --random
  echo ":: Next wallpaper in $sec seconds..."
  sleep "$sec"
}

if [[ ! -f "$automation_flag" ]]; then
  touch "$automation_flag"
  notify-send "Wallpaper automation started" "Wallpaper will change every $sec seconds."
  while [[ -f "$automation_flag" ]]; do _loop; done
else
  rm -f "$automation_flag"
  notify-send "Wallpaper automation stopped."
fi

