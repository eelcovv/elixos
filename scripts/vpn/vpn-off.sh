#!/usr/bin/env bash
set -euo pipefail

stopped=0
for iface in $(wg show interfaces 2>/dev/null || true); do
  if [[ "$iface" == wg-surfshark-* ]]; then
    sudo systemctl stop "wg-quick-${iface}.service" || true
    stopped=1
  fi
done

if [[ $stopped -eq 1 ]]; then
  echo "🛑 Surfshark VPN stopped"
else
  echo "⚠️  Surfshark VPN already stopped"
fi

