# hypr-switch-displays (autodetecting version)
# Modes:
#   auto   → if any external exists, external-only; else laptop-only
#   dock   → external-only (internal disabled)
#   mobile → laptop-only (external disabled)
#   dual   → both enabled; WS 1 on laptop, WS 2..10 on external
# Requires: hyprctl; jq (for JSON parsing)

set -euo pipefail

MODE="${1:-auto}"

# Query monitors once (JSON)
MON_JSON="$(hyprctl -j monitors)"

# Detect internal panel name (matches eDP/LVDS)
INTERNAL="$(printf '%s\n' "$MON_JSON" | jq -r '.[] | select(.name|test("(^|-)eDP|LVDS|edp|Edp")) | .name' | head -n1)"
# All monitor names
readarray -t ALL_MONITORS < <(printf '%s\n' "$MON_JSON" | jq -r '.[].name')

# Externals = all minus INTERNAL
EXTERNALS=()
for m in "${ALL_MONITORS[@]}"; do
  [[ -n "${INTERNAL:-}" && "$m" == "$INTERNAL" ]] && continue
  EXTERNALS+=("$m")
done
PRIMARY_EXT="${EXTERNALS[0]:-}"

# Tunables (you can change preferred/scale for your setup)
EXT_MODE="preferred"   # e.g. "3440x1440@120.00"
EXT_SCALE="1"
LAP_MODE="preferred"
LAP_SCALE="1"

enable_only_external() {
  [[ -z "${PRIMARY_EXT:-}" ]] && { echo "No external monitor found"; exit 1; }
  # Enable external with preferred mode, disable internal
  hyprctl keyword monitor "${PRIMARY_EXT},${EXT_MODE},auto,${EXT_SCALE}"
  [[ -n "${INTERNAL:-}" ]] && hyprctl keyword monitor "${INTERNAL},disable"
  # Move all workspaces to external
  for i in $(seq 1 10); do
    hyprctl dispatch moveworkspacetomonitor "$i" "$PRIMARY_EXT" >/dev/null 2>&1 || true
  done
  echo "Applied: external-only on ${PRIMARY_EXT}"
}

enable_only_laptop() {
  # Disable all externals, enable internal
  for m in "${EXTERNALS[@]}"; do
    hyprctl keyword monitor "${m},disable"
  done
  [[ -n "${INTERNAL:-}" ]] && hyprctl keyword monitor "${INTERNAL},${LAP_MODE},auto,${LAP_SCALE}"
  for i in $(seq 1 10); do
    [[ -n "${INTERNAL:-}" ]] && hyprctl dispatch moveworkspacetomonitor "$i" "$INTERNAL" >/dev/null 2>&1 || true
  done
  echo "Applied: laptop-only on ${INTERNAL:-unknown}"
}

enable_dual() {
  [[ -z "${INTERNAL:-}" || -z "${PRIMARY_EXT:-}" ]] && { echo "Need internal + external"; exit 1; }
  # Enable laptop at 0x0, external auto-place (often right)
  hyprctl keyword monitor "${INTERNAL},${LAP_MODE},0x0,${LAP_SCALE}"
  hyprctl keyword monitor "${PRIMARY_EXT},${EXT_MODE},auto,${EXT_SCALE}"
  # Route workspaces: 1 on laptop; 2..10 on external
  hyprctl dispatch moveworkspacetomonitor 1 "$INTERNAL" >/dev/null 2>&1 || true
  for i in $(seq 2 10); do
    hyprctl dispatch moveworkspacetomonitor "$i" "$PRIMARY_EXT" >/dev/null 2>&1 || true
  done
  echo "Applied: dual (1→${INTERNAL}, 2..10→${PRIMARY_EXT})"
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
    echo "Usage: hypr-switch-displays [auto|dock|mobile|dual]"; exit 2 ;;
esac

