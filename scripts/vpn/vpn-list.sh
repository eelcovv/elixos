#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   vpn-list.sh
#   vpn-list.sh --speedtest
#   vpn-list.sh --speedtest <loc>
#   vpn-list.sh --speedtest-all

arg1="${1-}"
arg2="${2-}"

# ---- flags (init once) ----
need_speedtest=false
mode_all=false
target_loc=""

case "${arg1:-}" in
  --speedtest)
    need_speedtest=true
    [[ -n "${arg2:-}" ]] && target_loc="${arg2}"
    ;;
  --speedtest-all)
    need_speedtest=true
    mode_all=true
    ;;
  "" )
    ;;
  *)
    echo "Usage: $0 [--speedtest [loc] | --speedtest-all]"
    exit 1
    ;;
esac

# We gebruiken speedtest-cli in run_speedtest(), dus check alleen die tool
if $need_speedtest && ! command -v speedtest-cli >/dev/null 2>&1; then
  echo "❌ 'speedtest-cli' not found. Install it (e.g. 'nix-shell -p speedtest-cli' or add to system)."
  exit 1
fi

echo "🌐 Available Surfshark locations:"

active_ifaces="$(wg show interfaces 2>/dev/null || true)"

# ---- vind alle wg-quick Surfshark units (systemd + filesystem) ----
mapfile -t from_sysd < <(systemctl list-units --all --type=service --no-legend \
  | awk '{print $1}' | grep -E '^wg-quick-wg-surfshark-.*\.service$' || true)

mapfile -t from_fs_raw < <(ls -1 /etc/systemd/system/wg-quick-wg-surfshark-* 2>/dev/null \
  | xargs -r -n1 basename || true)

normalized_fs=()
for name in "${from_fs_raw[@]:-}"; do
  [[ -z "${name:-}" ]] && continue
  name="${name%/}"
  [[ "$name" != *.service ]] && name="${name}.service"
  normalized_fs+=("$name")
done

mapfile -t units < <(printf '%s\n' "${from_sysd[@]:-}" "${normalized_fs[@]:-}" \
  | sed '/^$/d' | sort -u)

if [[ ${#units[@]} -eq 0 ]]; then
  echo "  (none found)"
  echo '  Hint: declare networking.wg-quick.interfaces."wg-surfshark-<loc>" in Nix and rebuild.'
  exit 0
fi

# ---- optionele bronnen voor endpoints ----
declare -A endpoints_json=()
if [[ -r /etc/wg-endpoints.json ]]; then
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

# ---- actieve locatie bepalen (eerste wg-surfshark-*) ----
active_loc=""
for iface in $active_ifaces; do
  if [[ "$iface" == wg-surfshark-* ]]; then
    active_loc="${iface#wg-surfshark-}"
    break
  fi
done
orig_loc="$active_loc"

# ---- helpers ----
get_endpoint() {
  local iface="$1" endpoint="n/a"
  # runtime (als actief)
  if echo "$active_ifaces" | tr ' ' '\n' | grep -qx "$iface"; then
    endpoint="$(sudo wg show "$iface" | awk '/endpoint:/ {print $2; exit}' || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi
  # conf
  if [[ "$endpoint" == "n/a" && -r "/etc/wireguard/${iface}.conf" ]]; then
    endpoint="$(awk -F'= *' '/^[[:space:]]*Endpoint[[:space:]]*=/ {print $2; exit}' "/etc/wireguard/${iface}.conf" || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi
  # Nix JSON
  if [[ "$endpoint" == "n/a" ]]; then
    endpoint="${endpoints_json[$iface]:-n/a}"
  fi
  # handmatige mapping
  if [[ "$endpoint" == "n/a" ]]; then
    endpoint="${endpoints_manual[$iface]:-n/a}"
  fi
  printf '%s' "$endpoint"
}

latency_to() {
  local host="$1" lat="n/a"
  if [[ -n "$host" ]]; then
    lat="$(ping -c 3 -q "$host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi
  printf '%s' "$lat"
}

start_loc() { sudo systemctl start "wg-quick-wg-surfshark-$1"; }
stop_loc()  { sudo systemctl stop  "wg-quick-wg-surfshark-$1" || true; }

wait_until_up() {
  local iface="$1" tries=30
  for _ in $(seq 1 $tries); do
    if wg show interfaces 2>/dev/null | tr ' ' '\n' | grep -qx "$iface"; then
      return 0
    fi
    sleep 0.5
  done
  return 0
}

run_speedtest() {
  timeout 90s speedtest-cli --secure --simple 2>/dev/null || true
}

# lijst locs
locs=()
for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"
  loc="${loc%.service}"
  locs+=("$loc")
done

# ---- hoofdloop ----
for loc in "${locs[@]}"; do
  iface="wg-surfshark-$loc"
  mark=" "
  [[ "$loc" == "$active_loc" ]] && mark="*"

  endpoint="$(get_endpoint "$iface")"
  host="${endpoint%%:*}"
  lat="$( [[ "$endpoint" != "n/a" ]] && latency_to "$host" || echo "n/a" )"

  if ! $need_speedtest; then
    printf " %s %-8s  endpoint=%-38s  latency=%s\n" "$mark" "$loc" "$endpoint" "$lat"
    continue
  fi

  # Bepaal of we voor deze loc een speedtest doen
  should_test=false
  if $mode_all; then
    should_test=true
  elif [[ -n "${target_loc:-}" ]]; then
    [[ "$loc" == "$target_loc" ]] && should_test=true
  else
    [[ -n "$active_loc" && "$loc" == "$active_loc" ]] && should_test=true
  fi

  if ! $should_test; then
    printf "   %-8s  endpoint=%-38s  latency=%s\n" "$loc" "$endpoint" "$lat"
    continue
  fi

  # Schakel indien nodig
  if [[ "$loc" != "$active_loc" ]]; then
    [[ -n "$active_loc" ]] && stop_loc "$active_loc"
    start_loc "$loc"
    wait_until_up "$iface"
    active_loc="$loc"
    active_ifaces="$iface"
  fi

  # Speedtest uitvoeren
  st="$(run_speedtest)"
  dl="$(echo "$st" | awk '/Download/ {print $2 " " $3}')"; [[ -z "$dl" ]] && dl="n/a"
  ul="$(echo "$st" | awk '/Upload/   {print $2 " " $3}')"; [[ -z "$ul" ]] && ul="n/a"
  sp="$(echo "$st" | awk '/Ping/     {print $2 " " $3}')"; [[ -z "$sp" ]] && sp="n/a"

  printf " * %-8s  endpoint=%-38s  latency=%-8s DL=%-10s UL=%-10s Ping=%s\n" \
    "$loc" "$endpoint" "$lat" "$dl" "$ul" "$sp"
done

# Herstel oorspronkelijke locatie als we gewisseld hebben
if $need_speedtest; then
  if [[ -n "${orig_loc:-}" && "$orig_loc" != "$active_loc" ]]; then
    stop_loc "$active_loc" || true
    start_loc "$orig_loc"
  fi
fi

echo "(* marks the currently active location)"

