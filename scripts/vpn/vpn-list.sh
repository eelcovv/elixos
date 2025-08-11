#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   vpn-list.sh                     # lijst + latency (snel)
#   vpn-list.sh --speedtest         # speedtest van huidige actieve locatie
#   vpn-list.sh --speedtest <loc>   # speedtest van specifieke locatie, herstelt daarna de oude
#   vpn-list.sh --speedtest-all     # **accurate**: test ALLE locaties (wisselt per locatie), herstelt daarna de oude

arg1="${1-}"
arg2="${2-}"

need_speedtest=false
mode_all=false
target_loc=""

if [[ "$arg1" == "--speedtest" ]]; then
  need_speedtest=true
  [[ -n "${arg2:-}" ]] && target_loc="$arg2"
elif [[ "$arg1" == "--speedtest-all" ]]; then
  need_speedtest=true
  mode_all=true
fi

if $need_speedtest && ! command -v speedtest-cli >/dev/null 2>&1; then
  echo "❌ 'speedtest-cli' not found. Install it (e.g. on NixOS: 'nix-shell -p speedtest-cli' or add it to your system)."
  exit 1
fi

echo "🌐 Available Surfshark locations:"

active_ifaces="$(wg show interfaces 2>/dev/null || true)"

# --- vind alle wg-quick Surfshark units (systemd + filesystem) ---
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

# --- optionele bronnen voor endpoints ---
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

# --- helper: actieve loc bepalen (eerste wg-surfshark-*) ---
active_loc=""
for iface in $active_ifaces; do
  if [[ "$iface" == wg-surfshark-* ]]; then
    active_loc="${iface#wg-surfshark-}"
    break
  fi
done
orig_loc="$active_loc"

# --- helpers ---
get_endpoint() {
  local iface="$1" endpoint="n/a"
  # 1) runtime als actief
  if echo "$active_ifaces" | tr ' ' '\n' | grep -qx "$iface"; then
    endpoint="$(sudo wg show "$iface" | awk '/endpoint:/ {print $2; exit}' || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi
  # 2) conf
  if [[ "$endpoint" == "n/a" && -r "/etc/wireguard/${iface}.conf" ]]; then
    endpoint="$(awk -F'= *' '/^[[:space:]]*Endpoint[[:space:]]*=/ {print $2; exit}' "/etc/wireguard/${iface}.conf" || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi
  # 3) Nix JSON
  if [[ "$endpoint" == "n/a" ]]; then
    endpoint="${endpoints_json[$iface]:-n/a}"
  fi
  # 4) handmatige mapping
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
  local iface="$1" tries=20
  # wacht tot interface zichtbaar is en handshake gezien werd (best effort)
  for _ in $(seq 1 $tries); do
    if wg show interfaces 2>/dev/null | tr ' ' '\n' | grep -qx "$iface"; then
      return 0
    fi
    sleep 0.5
  done
  return 0
}

run_speedtest() {
  # timeouts zodat het niet blijft hangen
  timeout 90s speedtest-cli --secure --simple 2>/dev/null || true
}

# --- bouw een nette lijst met korte loc-namen ---
locs=()
for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"
  loc="${loc%.service}"
  locs+=("$loc")
fi

# --- hoofdloop: print lijst en (optioneel) speedtests ---
for loc in "${locs[@]}"; do
  iface="wg-surfshark-$loc"
  mark=" "
  [[ "$loc" == "$active_loc" ]] && mark="*"

  endpoint="$(get_endpoint "$iface")"
  host="${endpoint%%:*}"
  lat="$( [[ "$endpoint" != "n/a" ]] && latency_to "$host" || echo "n/a" )"

  # Zonder speedtest: oude, snelle gedrag
  if ! $need_speedtest; then
    printf " %s %-8s  endpoint=%-38s  latency=%s\n" "$mark" "$loc" "$endpoint" "$lat"
    continue
  fi

  # --speedtest (huidig of specifiek) of --speedtest-all
  if $mode_all || [[ -n "${target_loc:-}" && "$loc" == "$target_loc" ]] || ([[ -z "${target_loc:-}" ]] && [[ "$loc" == "$active_loc" && -n "$active_loc" ]]); then
    # Schakel indien nodig
    if [[ "$loc" != "$active_loc" ]]; then
      [[ -n "$active_loc" ]] && stop_loc "$active_loc"
      start_loc "$loc"
      wait_until_up "$iface"
      active_loc="$loc"
      active_ifaces="$iface"
    fi

    # Run speedtest
    st="$(run_speedtest)"
    dl="$(echo "$st"   | awk '/Download/ {print $2 " " $3}')"; [[ -z "$dl" ]] && dl="n/a"
    ul="$(echo "$st"   | awk '/Upload/   {print $2 " " $3}')"; [[ -z "$ul" ]] && ul="n/a"
    sp="$(echo "$st"   | awk '/Ping/     {print $2 " " $3}')"; [[ -z "$sp" ]] && sp="n/a"

    printf " * %-8s  endpoint=%-38s  latency=%-8s DL=%-10s UL=%-10s Ping=%s\n" "$loc" "$endpoint" "$lat" "$dl" "$ul" "$sp"
  else
    # Alleen tonen, niet testen
    printf "   %-8s  endpoint=%-38s  latency=%s\n" "$loc" "$endpoint" "$lat"
  fi
done

# Herstel oorspronkelijke locatie als we met --speedtest-all of --speedtest <loc> gewisseld hebben
if $need_speedtest; then
  if [[ -n "${orig_loc:-}" && "$orig_loc" != "$active_loc" ]]; then
    stop_loc "$active_loc" || true
    start_loc "$orig_loc"
  fi
fi

echo "(* marks the currently active location)"

