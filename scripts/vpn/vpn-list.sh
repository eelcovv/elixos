#!/usr/bin/env bash
set -euo pipefail

echo "🌐 Available Surfshark locations:"

# Pak alleen de 1e kolom (unit name)
mapfile -t units < <(systemctl list-unit-files --type=service --no-legend \
  | awk '/^wg-quick-wg-surfshark-.*\.service/ {print $1}')

if [[ ${#units[@]} -eq 0 ]]; then
  echo "  (none found)"
  echo "  Hint: declare networking.wg-quick.interfaces.\"wg-surfshark-<loc>\" in Nix and rebuild."
  exit 0
fi

for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"
  loc="${loc%.service}"
  iface="wg-surfshark-${loc}"
  conf="/etc/wireguard/${iface}.conf"

  endpoint="n/a"
  ep_host=""
  if [[ -r "$conf" ]]; then
    endpoint="$(awk -F'= *' '/^[[:space:]]*Endpoint[[:space:]]*=/ {print $2; exit}' "$conf" || true)"
    ep_host="${endpoint%%:*}"
  fi

  lat="n/a"
  if [[ -n "$ep_host" ]]; then
    lat="$(ping -c 3 -q "$ep_host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi

  mark=" "
  systemctl is-active --quiet "$unit" && mark="*"

  printf " %s %-8s  endpoint=%-28s  latency=%s\n" "$mark" "$loc" "${endpoint:-n/a}" "$lat"
done

echo "(* marks the currently active location)"

