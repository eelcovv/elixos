#!/usr/bin/env bash
set -euo pipefail

active="$(wg show interfaces 2>/dev/null || true)"
active_loc=""
if [[ -n "$active" ]]; then
  # Neem de eerste wg-surfshark-*
  for iface in $active; do
    if [[ "$iface" == wg-surfshark-* ]]; then
      active_loc="${iface#wg-surfshark-}"
      break
    fi
  done
fi

if [[ -n "$active_loc" ]]; then
  echo "🔍 VPN status: ✅ active  (loc: ${active_loc})"
else
  echo "🔍 VPN status: ❌ inactive"
fi

echo "🌍 Public IP:"
curl -s ifconfig.me ; echo

if [[ -n "$active_loc" ]]; then
  iface="wg-surfshark-${active_loc}"
  echo "🔑 WireGuard handshake info:"
  sudo wg show "$iface" | grep -E "endpoint|latest handshake|transfer" || true
else
  echo "🔑 WireGuard handshake info: (VPN inactive)"
fi

