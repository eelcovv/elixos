#!/usr/bin/env bash

# Cliphist + Rofi integratie: decode, delete, wipe

choice="$1"
rofi_opts="-replace"

case "$choice" in
  d)
    cliphist list | rofi -dmenu $rofi_opts -config ~/.config/rofi/config-cliphist.rasi | cliphist delete
    ;;
  w)
    if echo -e "Clear\nCancel" | rofi -dmenu $rofi_opts -config ~/.config/rofi/config-short.rasi | grep -q "^Clear$"; then
      cliphist wipe
    fi
    ;;
  *)
    cliphist list | rofi -dmenu $rofi_opts -config ~/.config/rofi/config-cliphist.rasi | cliphist decode | wl-copy
    ;;
esac
