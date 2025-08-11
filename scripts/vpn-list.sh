#!/usr/bin/env bash
set -euo pipefail

# Lists Surfshark wg-quick locations, shows endpoint and a quick latency estimate.
# Marks the currently active location with an asterisk (*).

echo "🌐 Available Surfshark locations:"

# Discover wg-quick services that match our naming convention.
mapfile -t units < <(systemctl list-unit-files --type=service --no-legend \
  | awk '/^wg-quick-wg-surfshark-.*\.service$/ {print $1}')

if [[ ${#units[@]} -eq 0 ]]; then
  echo "  (none found)"
  exit 0
fi

for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"
  loc="${loc%.service}"
  iface="wg-surfshark-${loc}"
  conf="/etc/wireguard/${iface}.conf"   # wg-quick writes a merged conf here on start; may not exist if never started

  # Try to get Endpoint from the unit file. Fallback to conf if present.
  endpoint="$(systemctl cat "$unit" 2>/dev/null | awk -F'= *' '/^Endpoint=/ {print $2; exit}')"
  if [[ -z "$endpoint" && -r "$conf" ]]; then
    endpoint="$(awk -F'= *' '/^Endpoint[[:space:]]*=/ {print $2; exit}' "$conf" || true)"
  fi

  ep_host=""
  [[ -n "$endpoint" ]] && ep_host="${endpoint%%:*}"

  lat="n/a"
  if [[ -n "$ep_host" ]]; then
    # Quick 3‑packet ping; print avg RTT rounded (ms)
    lat="$(ping -c 3 -q "$ep_host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi

  mark=" "
  if systemctl is-active --quiet "$unit"; then
    mark="*"
  fi

  printf " %s %-8s  endpoint=%-28s  latency=%s\n" "$mark" "$loc" "${endpoint:-n/a}" "$lat"
done

echo "(* marks the currently active location)"
