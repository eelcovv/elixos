#!/usr/bin/env bash
set -Eeuo pipefail

# Bepaal simpele status
idle_on="off"
if pgrep -x hypridle >/dev/null; then
  idle_on="on"
fi

locked="no"
if pgrep -x hyprlock >/dev/null; then
  locked="yes"
fi

# Tekst + tooltip
lock_icon="🔓"
[ "$locked" = "yes" ] && lock_icon="🔒"

text="$lock_icon $idle_on"
tooltip="hypridle: $idle_on • locked: $locked"

# Geldige JSON voor Waybar (met text + tooltip velden)
printf '{ "text": "%s", "tooltip": "%s" }\n' "$text" "$tooltip"
