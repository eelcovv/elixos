#!/usr/bin/env bash
set -euo pipefail

# Usage: vpn-on.sh <loc>
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <loc>   (e.g. nl, bkk, sg)"
  exit 1
fi

LOC="$1"
TARGET="wg-quick-wg-surfshark-${LOC}.service"

# Check of de target-unit bestaat (kolom 1 vergelijken)
if ! systemctl list-unit-files --type=service --no-legend | awk -v t="$TARGET" '$1==t {found=1} END{exit found?0:1}'; then
  echo "❌ Unknown location '${LOC}'. Available:"
  systemctl list-unit-files --type=service --no-legend \
    | awk '/^wg-quick-wg-surfshark-.*\.service/ {gsub(/^wg-quick-wg-surfshark-|\.service$/,"",$1); print "  - "$1}'
  exit 1
fi

# Stop andere Surfshark-units indien actief
while read -r unit; do
  systemctl is-active --quiet "$unit" && sudo systemctl stop "$unit"
done < <(systemctl list-units --type=service --no-legend \
        | awk '/^wg-quick-wg-surfshark-.*\.service/ {print $1}')

sudo systemctl start "$TARGET"
echo "✅ Surfshark VPN started: ${LOC}"

