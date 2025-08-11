#!/usr/bin/env bash
set -euo pipefail

# Usage: vpn-on.sh <loc>
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <loc>   (e.g. nl, bk, sg)"
  exit 1
fi
LOC="$1"
TARGET="wg-quick-wg-surfshark-${LOC}.service"

# Bestaat de target-unit? (match kolom 1)
if ! systemctl list-unit-files --type=service --no-legend | awk -v t="$TARGET" '$1==t {f=1} END{exit f?0:1}'; then
  echo "❌ Unknown location '${LOC}'. Available:"
  systemctl list-unit-files --type=service --no-legend \
    | awk '/^wg-quick-wg-surfshark-.*\.service$/ {gsub(/^wg-quick-wg-surfshark-|\.service$/,"",$1); print "  - "$1}'
  exit 1
fi

# Stop alle actieve Surfshark-interfaces (via wg, niet via raden)
for iface in $(wg show interfaces 2>/dev/null || true); do
  if [[ "$iface" == wg-surfshark-* ]]; then
    sudo systemctl stop "wg-quick-${iface}.service" || true
  fi
done

sudo systemctl start "$TARGET"
echo "✅ Surfshark VPN started: ${LOC}"

