#!/usr/bin/env bash
set -euo pipefail

echo "🌐 Available Surfshark locations:"

# Alle mogelijke wg-quick units (1e kolom)
mapfile -t units < <(systemctl list-unit-files --type=service --no-legend \
  | awk '/^wg-quick-wg-surfshark-.*\.service$/ {print $1}')

if [[ ${#units[@]} -eq 0 ]]; then
  echo "  (none found)"
  echo "  Hint: declare networking.wg-quick.interfaces.\"wg-surfshark-<loc>\" in Nix and rebuild."
  exit 0
fi

# Huidig actieve WG-interfaces (betrouwbaar)
active_ifaces="$(wg show interfaces 2>/dev/null || true)"

for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"; loc="${loc%.service}"
  iface="wg-surfshark-${loc}"
  mark=" "
  if echo "$active_ifaces" | tr ' ' '\n' | grep -qx "$iface"; then
    mark="*"
  fi

  endpoint="n/a"
  # Als actief: lees runtime endpoint
  if [[ "$mark" == "*" ]]; then
    endpoint="$(sudo wg show "$iface" | awk '/endpoint:/ {print $2; exit}')"
  fi
  # Zo niet, probeer conf bestand (kan ontbreken als nooit gestart)
  if [[ "$endpoint" == "n/a" && -r "/etc/wireguard/${iface}.conf" ]]; then
    endpoint="$(awk -F'= *' '/^[[:space:]]*Endpoint[[:space:]]*=/ {print $2; exit}' "/etc/wireguard/${iface}.conf" || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi

  # Snelheids-indicatie: ping de host (als we er één hebben)
  lat="n/a"
  if [[ "$endpoint" != "n/a" ]]; then
    ep_host="${endpoint%%:*}"
    lat="$(ping -c 3 -q "$ep_host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi

  printf " %s %-8s  endpoint=%-28s  latency=%s\n" "$mark" "$loc" "$endpoint" "$lat"
done

echo "(* marks the currently active location)"

