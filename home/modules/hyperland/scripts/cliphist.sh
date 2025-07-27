#!/usr/bin/env bash

# Cliphist + Rofi integratie: decode, delete, wipe

choice="$1"
rofi_opts="-replace"
rofi_config="$HOME/.config/rofi/config.rasi"

case "$choice" in
  d)
    cliphist list | rofi -dmenu $rofi_opts -config "$rofi_config" | cliphist delete
    ;;
  w)
    if echo -e "Clear\nCancel" | rofi -dmenu $rofi_opts -config "$rofi_config" | grep -q "^Clear$"; then
      cliphist wipe
    fi
    ;;
  *)
    cliphist list | rofi -dmenu $rofi_opts -config "$rofi_config" | cliphist decode | wl-copy
    ;;
esac

