#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <loc>   (e.g. nl, bkk, sg)"
  exit 1
fi

LOC="$1"
TARGET="wg-quick-wg-surfshark-${LOC}.service"

# Stop any running Surfshark wg-quick services
while read -r unit; do
  systemctl is-active --quiet "$unit" && sudo systemctl stop "$unit"
done < <(systemctl list-units --type=service --no-legend \
        | awk '/^wg-quick-wg-surfshark-.*\.service$/ {print $1}')

# Start requested
if systemctl list-unit-files --type=service --no-legend | grep -q "^${TARGET}$"; then
  sudo systemctl start "$TARGET"
  echo "✅ Surfshark VPN started: ${LOC}"
else
  echo "❌ Unknown location '${LOC}'. Available:"
  systemctl list-unit-files --type=service --no-legend \
    | awk '/^wg-quick-wg-surfshark-.*\.service$/ {gsub(/^wg-quick-wg-surfshark-|\.service$/,"",$1); print "  - "$1}'
  exit 1
fi

