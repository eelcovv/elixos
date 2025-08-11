#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   vpn-list.sh                 # list + latency (zoals voorheen)
#   vpn-list.sh --speedtest     # speedtest van huidige actieve locatie
#   vpn-list.sh --speedtest nl  # speedtest van specifieke locatie (herstelt daarna oude)
#   vpn-list.sh --speedtest-all # speedtest van alle locaties (herstelt daarna oude)

arg1="${1-}"
arg2="${2-}"

need_speedtest=false
mode_all=false
target_loc=""

if [[ "$arg1" == "--speedtest" ]]; then
  need_speedtest=true
  [[ -n "$arg2" ]] && target_loc="$arg2"
elif [[ "$arg1" == "--speedtest-all" ]]; then
  need_speedtest=true
  mode_all=true
fi

if $need_speedtest && ! command -v speedtest-cli >/dev/null 2>&1; then
  echo "❌ 'speedtest-cli' not found. Install it (e.g. on NixOS: 'nix-shell -p speedtest-cli' or add to system)."
  exit 1
fi

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

# Handmatige mapping (optioneel)
declare -A endpoints_manual=()
if [[ -r "$HOME/.config/surfshark-endpoints" ]]; then
  while IFS='=' read -r k v; do
    [[ -z "${k:-}" || -z "${v:-}" ]] && continue
    endpoints_manual["wg-surfshark-$k"]="$v"
  done < "$HOME/.config/surfshark-endpoints"
fi

# Bepaal actieve locatie (eerste wg-surfshark-*)
active_loc=""
for iface in $active_ifaces; do
  if [[ "$iface" == wg-surfshark-* ]]; then
    active_loc="${iface#wg-surfshark-}"
    break
  fi
done

# Helper: endpoint van een iface bepalen (runtime -> conf -> JSON -> manual)
get_endpoint() {
  local iface="$1" endpoint="n/a"

  # 1) runtime (als actief)
  if echo "$active_ifaces" | tr ' ' '\n' | grep -qx "$iface"; then
    endpoint="$(sudo wg show "$iface" | awk '/endpoint:/ {print $2; exit}' || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi

  # 2) conf-bestand
  if [[ "$endpoint" == "n/a" && -r "/etc/wireguard/${iface}.conf" ]]; then
    endpoint="$(awk -F'= *' '/^[[:space:]]*Endpoint[[:space:]]*=/ {print $2; exit}' "/etc/wireguard/${iface}.conf" || true)"
    [[ -z "$endpoint" ]] && endpoint="n/a"
  fi

  # 3) Nix JSON
  if [[ "$endpoint" == "n/a" ]]; then
    endpoint="${endpoints_json[$iface]:-n/a}"
  fi

  # 4) Handmatige mapping
  if [[ "$endpoint" == "n/a" ]]; then
    endpoint="${endpoints_manual[$iface]:-n/a}"
  fi

  printf '%s' "$endpoint"
}

# Helper: latency meten naar host (ICMP)
latency_to() {
  local host="$1"
  local lat="n/a"
  if [[ -n "$host" ]]; then
    lat="$(ping -c 3 -q "$host" 2>/dev/null | awk -F'/' '/^rtt/ {printf "%.0f ms", $5}')"
    [[ -z "$lat" ]] && lat="n/a"
  fi
  printf '%s' "$lat"
}

# Helper: start/stop
start_loc() { sudo systemctl start "wg-quick-wg-surfshark-$1"; }
stop_loc()  { sudo systemctl stop  "wg-quick-wg-surfshark-$1" || true; }

# Helper: speedtest (returns "DL=<..> UL=<..> Ping=<..>")
run_speedtest() {
  local out dl ul ping
  out="$(speedtest-cli --secure --simple 2>/dev/null || true)"
  dl="$(echo "$out" | awk '/Download/ {print $2 " " $3}')"
  ul="$(echo "$out" | awk '/Upload/   {print $2 " " $3}')"
  ping="$(echo "$out"| awk '/Ping/     {print $2 " " $3}')"
  [[ -z "$dl" ]] && dl="n/a"; [[ -z "$ul" ]] && ul="n/a"; [[ -z "$ping" ]] && ping="n/a"
  printf 'DL=%s UL=%s Ping=%s' "$dl" "$ul" "$ping"
}

# Als we in speedtest-all modus zijn, onthoud dan de originele locatie
orig_loc="$active_loc"

# Verzamel locs (kortere loc naam)
locs=()
for unit in "${units[@]}"; do
  loc="${unit#wg-quick-wg-surfshark-}"; loc="${loc%.service}"
  locs+=("$loc")
done

# ------------------------------------------------------
# LIST (altijd) + optioneel SPEEDTEST
# ------------------------------------------------------
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

  # Speedtest logic
  if $mode_all; then
    # Stop actieve, start target, test, herstel
    [[ -n "$active_loc" ]] && stop_loc "$active_loc"
    start_loc "$loc"
    sleep 3
    st="$(run_speedtest)"
    stop_loc "$loc"
    [[ -n "$orig_loc" ]] && start_loc "$orig_loc"
    # mark is "*" alleen als deze ook de actieve was vóór listing
    printf " %s %-8s  endpoint=%-38s  latency=%-8s %s\n" "$mark" "$loc" "$endpoint" "$lat" "$st"
  else
    # Alleen huidige of (optioneel) specifieke target_loc
    if [[ -n "$target_loc" ]]; then
      # test alleen als dit de gewenste loc is
      if [[ "$loc" == "$target_loc" ]]; then
        [[ -n "$active_loc" && "$active_loc" != "$loc" ]] && stop_loc "$active_loc"
        start_loc "$loc"; sleep 3
        st="$(run_speedtest)"
        # herstel vorige staat: als hij niet al actief was, zet hem weer uit of switch terug
        if [[ -n "$active_loc" && "$active_loc" != "$loc" ]]; then
          stop_loc "$loc"
          start_loc "$active_loc"
        fi
        printf " %s %-8s  endpoint=%-38s  latency=%-8s %s\n" "$mark" "$loc" "$endpoint" "$lat" "$st"
      else
        printf "   %-8s  endpoint=%-38s  latency=%s\n" "$loc" "$endpoint" "$lat"
      fi
    else
      # --speedtest zonder target: test alleen actieve (als er één is)
      if [[ "$loc" == "$active_loc" && -n "$active_loc" ]]; then
        st="$(run_speedtest)"
        printf " * %-8s  endpoint=%-38s  latency=%-8s %s\n" "$loc" "$endpoint" "$lat" "$st"
      else
        printf "   %-8s  endpoint=%-38s  latency=%s\n" "$loc" "$endpoint" "$lat"
      fi
    fi
  fi
done

echo "(* marks the currently active location)"

