#!/usr/bin/env bash
# Single-list theme picker for Waybar.
set -euo pipefail

# Zorg dat ~/.local/bin in PATH zit (Hyprland exec heeft dit niet altijd)
export PATH="$HOME/.local/bin:$PATH"

# --- Vind & source de helper --------------------------------------------------
HELPER_CANDIDATES=(
  "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/helper-functions.sh"
  "$(dirname -- "${BASH_SOURCE[0]}")/helper-functions.sh"
)
FOUND=""
for f in "${HELPER_CANDIDATES[@]}"; do
  if [[ -r "$f" ]]; then
    # shellcheck disable=SC1090
    . "$f"
    FOUND="$f"
    break
  fi
done
if [[ -z "$FOUND" ]]; then
  echo "helper-functions.sh not found. Tried: ${HELPER_CANDIDATES[*]}" >&2
  exit 1
fi

