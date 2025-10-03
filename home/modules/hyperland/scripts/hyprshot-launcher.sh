#!/usr/bin/env bash
# hyprshot-launcher.sh — wrapper script for Hyprshot
#
# Usage:
#   hyprshot-launcher.sh [screen|region|window|selection]
#
# Default: "screen" (== full monitor)
#
# Features:
# - "selection" opens a simple menu (rofi/wofi/zenity) to pick the mode
# - Sends a desktop notification if 'notify-send' is available
# - Safe defaults, strict error handling

set -euo pipefail

notify() {
  # Send a desktop notification if available
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Hyprshot" "$1"
  fi
}

pick_mode() {
  # Try rofi → wofi → zenity in that order
  local choice
  if command -v rofi >/dev/null 2>&1; then
    choice="$(printf "screen\nregion\nwindow\ncancel" | rofi -dmenu -p "Hyprshot mode")"
  elif command -v wofi >/dev/null 2>&1; then
    choice="$(printf "screen\nregion\nwindow\ncancel" | wofi --dmenu --prompt "Hyprshot mode")"
  elif command -v zenity >/dev/null 2>&1; then
    choice="$(zenity --list --title="Hyprshot" --text="Select mode" --column="Mode" screen region window cancel || true)"
  else
    echo "No supported picker (rofi/wofi/zenity) found." >&2
    return 1
  fi

  case "${choice:-}" in
    screen|region|window) echo "$choice" ;;
    *) echo "cancel" ;;
  esac
}

run_mode() {
  # Map friendly names to Hyprshot arguments
  case "$1" in
    screen)  hyprshot -m monitor ;;
    region)  hyprshot -m region  ;;
    window)  hyprshot -m window  ;;
    *)       echo "Unknown mode: $1" >&2; exit 2 ;;
  esac
}

main() {
  local mode="${1:-screen}"

  if ! command -v hyprshot >/dev/null 2>&1; then
    notify "Hyprshot is not installed or not in PATH"
    echo "Hyprshot not found in PATH" >&2
    exit 127
  fi

  case "$mode" in
    selection)
      picked="$(pick_mode || true)"
      if [ "${picked:-cancel}" = "cancel" ]; then
        notify "Screenshot cancelled"
        exit 0
      fi
      run_mode "$picked"
      notify "Screenshot (${picked}) taken"
      ;;
    screen|region|window)
      run_mode "$mode"
      notify "Screenshot (${mode}) taken"
      ;;
    *)
      echo "Usage: $0 [screen|region|window|selection]" >&2
      exit 2
      ;;
  esac
}

main "$@"

