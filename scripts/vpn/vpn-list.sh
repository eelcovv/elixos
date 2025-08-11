#!/usr/bin/env bash
set -euo pipefail

echo "🌐 Available Surfshark locations:"

# A) actieve WG-interfaces (bron van waarheid)
active_ifaces="$(wg show interfaces 2>/dev/null || true)"

# B) services uit systemd (alle, incl. inactive)
mapfile -t from_sysd < <(
  systemctl list-units --all --type=service --no-legend \
    | awk '{print $1}' \
    | grep -E '^wg-quick-wg-surfshark-.*\.service$' \
    || true
)

# C) fallback: filesystem entries (soms zonder .service)
mapfile -t from_fs_raw < <(
  ls -1 /etc/systemd/system/wg-quick-wg-surfshark-* 2>/dev/null \
    | xargs -r -n1 basename || true
)

# Normaliseer -> altijd .service-suffix
normalized_fs=()
for name in "${from_fs_raw[@]}"; do
  [[ -z "$name" ]] && continue
  name="${name%/}"
  [[ "$name" != *.service ]] && name="${name}.service"
  normalized_fs+=("$name")
done

# Combineer en dedup unit-namen
mapfile -t units < <(
  printf '%s\n' "${from_sysd[@]}" "${normalized_fs[@]}" \
    | sed '/^$/d' | sort -u
)

if [[ ${#units[@]} -eq 0 ]]; then
  echo "  (none found)"
  echo '  Hint: declare networking.wg-quick.interfaces."wg-surfshark-<loc>" in Nix and rebuild.'
  exit 0
fi

for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"; loc="${loc%.service}"
  iface="wg-surfshark-${loc}"

  # actief?
  mark=" "
  if echo "$active_ifaces" | tr ' ' '\n' | grep -qx "$iface"; then
    mark="*"
  fi

  # Endpoint bepalen:
  endpoint="n/a"

  # 1) runtime als actief
  if [[ "$mark" == "*" ]]; then
    endpoint="$(sudo wg show "$iface" | awk '/endpoint:/ {print $2; exit}' || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi

  # 2) conf-bestand (als ooit gestart of door Nix ge-symlinkt)
  if [[ "$endpoint" == "n/a" && -r "/etc/wireguard/${iface}.conf" ]]; then
    endpoint="$(awk -F'= *' '/^[[:space:]]*Endpoint[[:space:]]*=/ {print $2; exit}' "/etc/wireguard/${iface}.conf" || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi

  # 3) NixOS config als fallback (leest endpoint uit je declaratie)
  if [[ "$endpoint" == "n/a" ]]; then
    # nixos-option print de hele structuur; grep het endpoint eruit
    # Werkt op hosts waar nixos-option beschikbaar is (standaard op NixOS).
    raw="$(nixos-option "networking.wg-quick.interfaces.\"${iface}\".peers" 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then
      # Pak de eerste regel met endpoint = "...";
      endpoint_guess="$(printf '%s\n' "$raw" | sed -nE 's/.*endpoint = "([^"]+)".*/\1/p' | head -n1)"
      [[ -n "$endpoint_guess" ]] && endpoint="$endpoint_guess"
    fi
  fi

  # Latency (alleen als we een host/ip hebben)
  lat="n/a"
  if [[ "$endpoint" != "n/a" ]]; then
    ep_host="${endpoint%%:*}"
    # Let op: ICMP kan soms geblokkeerd zijn, dan blijft lat 'n/a'
    lat="$(ping -c 3 -q "$ep_host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi

  printf " %s %-8s  endpoint=%-28s  latency=%s\n" "$mark" "$loc" "$endpoint" "$lat"
done

echo "(* marks the currently active location)"

