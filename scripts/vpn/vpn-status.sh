#!/usr/bin/env bash
set -euo pipefail

active="$(systemctl list-units --type=service --no-legend \
  | awk '/^wg-quick-wg-surfshark-.*\.service/ {print $1}' \
  | while read -r u; do systemctl is-active --quiet "$u" && echo "$u"; done \
  | sed 's/^wg-quick-wg-surfshark-\(.*\)\.service/\1/')"

if [[ -n "$active" ]]; then
  echo "🔍 VPN status: ✅ active  (loc: ${active})"
else
  echo "🔍 VPN status: ❌ inactive"
fi

echo "🌍 Public IP:"
curl -s ifconfig.me ; echo

if [[ -n "$active" ]]; then
  iface="wg-surfshark-${active}"
  echo "🔑 WireGuard handshake info:"
  sudo wg show "$iface" | grep -E "endpoint|latest handshake|transfer" || true
else
  echo "🔑 WireGuard handshake info: (VPN inactive)"
fi

