#!/usr/bin/env bash
set -euo pipefail

echo "🌐 Available Surfshark locations:"

active_ifaces="$(wg show interfaces 2>/dev/null || true)"

# Units via systemd en filesystem (gecombineerd + gededuped)
mapfile -t from_sysd < <(systemctl list-units --all --type=service --no-legend \
  | awk '{print $1}' | grep -E '^wg-quick-wg-surfshark-.*\.service$' || true)
mapfile -t from_fs_raw < <(ls -1 /etc/systemd/system/wg-quick-wg-surfshark-* 2>/dev/null | xargs -r -n1 basename || true)

normalized_fs=()
for name in "${from_fs_raw[@]}"; do
  [[ -z "$name" ]] && continue
  name="${name%/}"
  [[ "$name" != *.service ]] && name="${name}.service"
  normalized_fs+=("$name")
done

mapfile -t units < <(printf '%s\n' "${from_sysd[@]}" "${normalized_fs[@]}" | sed '/^$/d' | sort -u)

if [[ ${#units[@]} -eq 0 ]]; then
  echo "  (none found)"
  echo '  Hint: declare networking.wg-quick.interfaces."wg-surfshark-<loc>" in Nix and rebuild.'
  exit 0
fi

# Lees Nix‑gepubliceerde endpoints (optioneel)
declare -A endpoints_json=()
if [[ -r /etc/wg-endpoints.json ]]; then
  # shellcheck disable=SC2016
  while IFS= read -r k && IFS= read -r v; do
    endpoints_json["$k"]="$v"
  done < <(jq -r 'to_entries[] | .key, .value' /etc/wg-endpoints.json 2>/dev/null || true)
fi


declare -A endpoints_manual=()
if [[ -r "$HOME/.config/surfshark-endpoints" ]]; then
  while IFS='=' read -r k v; do
    [[ -z "${k:-}" || -z "${v:-}" ]] && continue
    endpoints_manual["wg-surfshark-$k"]="$v"
  done < "$HOME/.config/surfshark-endpoints"
fi

for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"; loc="${loc%.service}"
  iface="wg-surfshark-${loc}"

  mark=" "
  if echo "$active_ifaces" | tr ' ' '\n' | grep -qx "$iface"; then
    mark="*"
  fi

  endpoint="n/a"

  # 1) runtime endpoint als actief
  if [[ "$mark" == "*" ]]; then
    endpoint="$(sudo wg show "$iface" | awk '/endpoint:/ {print $2; exit}' || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi

  # 2) conf-bestand
  if [[ "$endpoint" == "n/a" && -r "/etc/wireguard/${iface}.conf" ]]; then
    endpoint="$(awk -F'= *' '/^[[:space:]]*Endpoint[[:space:]]*=/ {print $2; exit}' "/etc/wireguard/${iface}.conf" || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi

  # 3) Nix JSON (altijd beschikbaar na rebuild)
  if [[ "$endpoint" == "n/a" ]]; then
    endpoint="${endpoints_json[$iface]:-n/a}"
  fi

  # 4) handmatige mapping
  if [[ "$endpoint" == "n/a" ]]; then
    endpoint="${endpoints_manual[$iface]:-n/a}"
  fi

  lat="n/a"
  if [[ "$endpoint" != "n/a" ]]; then
    ep_host="${endpoint%%:*}"
    lat="$(ping -c 3 -q "$ep_host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi

  printf " %s %-8s  endpoint=%-38s  latency=%s\n" "$mark" "$loc" "$endpoint" "$lat"
done

echo "(* marks the currently active location)"

