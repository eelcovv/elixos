#!/usr/bin/env bash
# Switch display profiles in Hyprland.
# Modes:
#   - auto   → if external monitor exists, use dock; otherwise use laptop only
#   - dock   → external only (laptop off)
#   - mobile → laptop only (external off)
#   - dual   → both enabled, laptop left + workspace 1 on laptop, rest on external

set -euo pipefail

LAPTOP="eDP-2"
EXTERNAL="DP-1"

# Adjust modes and scales as needed
EX_MODE="3440x1440@59.97"
EX_SCALE="1"
LAPTOP_MODE="preferred"
LAPTOP_SCALE="1"

has_external() {
  hyprctl monitors | grep -q "^Monitor ${EXTERNAL} "
}

enable_only_external() {
  hyprctl keyword monitor "${LAPTOP},disable"
  hyprctl keyword monitor "${EXTERNAL},${EX_MODE},auto,${EX_SCALE}"
  # Move all workspaces to external
  for i in $(seq 1 10); do
    hyprctl dispatch moveworkspacetomonitor "${i}" "${EXTERNAL}" >/dev/null 2>&1 || true
  done
}

enable_only_laptop() {
  hyprctl keyword monitor "${EXTERNAL},disable"
  hyprctl keyword monitor "${LAPTOP},${LAPTOP_MODE},auto,${LAPTOP_SCALE}"
  # Move all workspaces to laptop
  for i in $(seq 1 10); do
    hyprctl dispatch moveworkspacetomonitor "${i}" "${LAPTOP}" >/dev/null 2>&1 || true
  done
}

enable_dual() {
  # Enable both, position external to the right of laptop
  hyprctl keyword monitor "${LAPTOP},${LAPTOP_MODE},0x0,${LAPTOP_SCALE}"
  hyprctl keyword monitor "${EXTERNAL},${EX_MODE},auto,${EX_SCALE}"
  # Route workspaces: 1 on laptop, 2..10 on external
  hyprctl dispatch moveworkspacetomonitor 1 "${LAPTOP}" >/dev/null 2>&1 || true
  for i in $(seq 2 10); do
    hyprctl dispatch moveworkspacetomonitor "${i}" "${EXTERNAL}" >/dev/null 2>&1 || true
  done
}

usage() {
  echo "Usage: $(basename "$0") [auto|dock|mobile|dual]"
  exit 1
}

mode="${1:-auto}"

case "$mode" in
  auto)
    if has_external; then
      enable_only_external
    else
      enable_only_laptop
    fi
    ;;
  dock)
    enable_only_external
    ;;
  mobile)
    enable_only_laptop
    ;;
  dual)
    enable_dual
    ;;
  *)
    usage
    ;;
esac

echo "Display profile applied: ${mode}"
