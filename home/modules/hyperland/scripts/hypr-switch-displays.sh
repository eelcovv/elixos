#!/usr/bin/env bash
# Switch display profiles in Hyprland (auto-detect outputs).
# Modes:
#   auto   → if any external exists, external-only; else laptop-only
#   dock   → external-only (internal disabled)
#   mobile → laptop-only (external disabled)
#   dual   → both enabled; workspace 1 on laptop, 2..10 on external
#
# Requires: hyprctl, jq

set -euo pipefail

MODE="${1:-auto}"

# Query monitors; prefer "all" (includes disabled) if supported
MON_JSON_ALL="$(hyprctl -j monitors all 2>/dev/null || true)"
if [[ -z "$MON_JSON_ALL" || "$MON_JSON_ALL" == "null" ]]; then
  MON_JSON_ALL="[]"
fi
MON_JSON_ENABLED="$(hyprctl -j monitors)"

# Helper to pick internal (eDP/LVDS) from a JSON array of monitors
pick_internal() {
  local json="$1"
  printf '%s\n' "$json" \
    | jq -r '.[] | select(.name|test("(^|-)eDP|LVDS|edp|Edp")) | .name' \
    | head -n1
}

# Detect internal from ALL first (so we find it even when disabled), else from enabled list
INTERNAL="$(pick_internal "$MON_JSON_ALL")"
if [[ -z "${INTERNAL:-}" ]]; then
  INTERNAL="$(pick_internal "$MON_JSON_ENABLED" || true)"
fi

# Collect all names (prefer ALL so disabled externals are known)
readarray -t ALL_MONITORS < <(printf '%s\n' "$MON_JSON_ALL" | jq -r '.[].name')
if [[ "${#ALL_MONITORS[@]}" -eq 0 ]]; then
  readarray -t ALL_MONITORS < <(printf '%s\n' "$MON_JSON_ENABLED" | jq -r '.[].name')
fi

# Externals = all minus INTERNAL
EXTERNALS=()
for m in "${ALL_MONITORS[@]}"; do
  [[ -n "${INTERNAL:-}" && "$m" == "$INTERNAL" ]] && continue
  EXTERNALS+=("$m")
done
PRIMARY_EXT="${EXTERNALS[0]:-}"

# Tunables (adjust as needed)
EXT_MODE="preferred"   # e.g. "3440x1440@120.00"
EXT_SCALE="1"
LAP_MODE="preferred"
LAP_SCALE="1"

enable_only_external() {
  [[ -z "${PRIMARY_EXT:-}" ]] && { echo "No external monitor found"; exit 1; }
  hyprctl keyword monitor "${PRIMARY_EXT},${EXT_MODE},auto,${EXT_SCALE}"
  [[ -n "${INTERNAL:-}" ]] && hyprctl keyword monitor "${INTERNAL},disable"
  for i in $(seq 1 10); do
    hyprctl dispatch moveworkspacetomonitor "$i" "$PRIMARY_EXT" >/dev/null 2>&1 || true
  done
  echo "Display profile applied: external-only (${PRIMARY_EXT})"
}

enable_only_laptop() {
  for m in "${EXTERNALS[@]}"; do
    hyprctl keyword monitor "${m},disable"
  done
  [[ -n "${INTERNAL:-}" ]] && hyprctl keyword monitor "${INTERNAL},${LAP_MODE},auto,${LAP_SCALE}"
  for i in $(seq 1 10); do
    [[ -n "${INTERNAL:-}" ]] && hyprctl dispatch moveworkspacetomonitor "$i" "$INTERNAL" >/dev/null 2>&1 || true
  done
  echo "Display profile applied: laptop-only (${INTERNAL:-unknown})"
}

enable_dual() {
  [[ -z "${INTERNAL:-}" || -z "${PRIMARY_EXT:-}" ]] && { echo "Need internal + external"; exit 1; }
  # Make sure internal is (re)enabled even if currently disabled
  hyprctl keyword monitor "${INTERNAL},${LAP_MODE},0x0,${LAP_SCALE}"
  # Small settle to avoid races on some setups
  sleep 0.15
  hyprctl keyword monitor "${PRIMARY_EXT},${EXT_MODE},auto,${EXT_SCALE}"
  # Route workspaces: 1 on laptop; 2..10 on external
  hyprctl dispatch moveworkspacetomonitor 1 "$INTERNAL" >/dev/null 2>&1 || true
  for i in $(seq 2 10); do
    hyprctl dispatch moveworkspacetomonitor "$i" "$PRIMARY_EXT" >/dev/null 2>&1 || true
  done
  echo "Display profile applied: dual (1→${INTERNAL}, 2..10→${PRIMARY_EXT})"
}

case "$MODE" in
  auto)
    if [[ -n "${PRIMARY_EXT:-}" ]]; then
      enable_only_external
    else
      enable_only_laptop
    fi
    ;;
  dock)   enable_only_external ;;
  mobile) enable_only_laptop ;;
  dual)   enable_dual ;;
  *)
    echo "Usage: $(basename "$0") [auto|dock|mobile|dual]"; exit 2 ;;
esac

