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
  echo "  Hint:"
  echo "    - Ensure you declared networking.wg-quick.interfaces.\"wg-surfshark-<loc>\" in Nix"
  echo "    - Run: nixos-option networking.wg-quick.interfaces"
  echo "    - Then: sudo nixos-rebuild switch"
  exit 0
fi

for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"; loc="${loc%.service}"
  endpoint="$(systemctl cat "$unit" 2>/dev/null | awk -F'= *' '/^Endpoint=/ {print $2; exit}')"
  ep_host="${endpoint%%:*}"
  lat="n/a"
  if [[ -n "${ep_host:-}" ]]; then
    lat="$(ping -c 3 -q "$ep_host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi
  mark=" "; systemctl is-active --quiet "$unit" && mark="*"
  printf " %s %-8s  endpoint=%-28s  latency=%s\n" "$mark" "$loc" "${endpoint:-n/a}" "$lat"
done

echo "(* marks the currently active location)"

