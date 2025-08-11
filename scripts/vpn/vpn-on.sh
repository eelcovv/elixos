#!/usr/bin/env bash
set -euo pipefail

# Usage: vpn-on.sh <loc>
# Starts the requested Surfshark wg-quick location after stopping any other Surfshark tunnels.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <loc>   (e.g. nl, bkk, sg)"
  exit 1
fi

LOC="$1"
TARGET="wg-quick-wg-surfshark-${LOC}.service"

# Stop any running Surfshark wg-quick services first.
while read -r unit; do
  if systemctl is-active --quiet "$unit"; then
    sudo systemctl stop "$unit"
  fi
done < <(systemctl list-units --type=service --no-legend | awk '/^wg-quick-wg-surfshark-.*\.service$/ {print $1}')

# Verify the target exists.
if ! systemctl list-unit-files --type=service --no-legend | grep -q "^${TARGET}\$"; then
  echo "❌ Unknown location '${LOC}'. Run vpn-list.sh to see available ones."
  exit 1
fi

sudo systemctl start "$TARGET"
echo "✅ Surfshark VPN started: ${LOC}"
