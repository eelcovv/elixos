#!/usr/bin/env bash
# Switch Waybar theme via helper-functions.sh
# Usage: waybar-switch-theme <theme> <variant>
# Example: waybar-switch-theme ml4w-minimal light
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $(basename "$0") <theme> <variant>"
  exit 1
fi

theme="$1"
variant="$2"
combo="${theme}/${variant}"

HELPER="$HOME/.config/hypr/scripts/helper-functions.sh"
if [[ -r "$HELPER" ]]; then
  # shellcheck disable=SC1090
  source "$HELPER"
else
  echo "ERROR: helper not found at $HELPER" >&2
  exit 1
fi

if ! type -t switch_theme >/dev/null 2>&1; then
  echo "ERROR: switch_theme() not found in helper" >&2
  exit 1
fi

switch_theme "$combo"

