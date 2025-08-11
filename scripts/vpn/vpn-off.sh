#!/usr/bin/env bash
set -euo pipefail

# Stops any active Surfshark wg-quick services.

stopped=0
while read -r unit; do
  if systemctl is-active --quiet "$unit"; then
    sudo systemctl stop "$unit"
    stopped=1
  fi
done < <(systemctl list-units --type=service --no-legend | awk '/^wg-quick-wg-surfshark-.*\.service$/ {print $1}')

if [[ $stopped -eq 1 ]]; then
  echo "🛑 Surfshark VPN stopped"
else
  echo "⚠️  Surfshark VPN already stopped"
fi
