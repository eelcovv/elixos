#!/usr/bin/env bash
set -euo pipefail

# Switch Waybar theme via helper-functions.sh.
# Accepts either:
#   1) <theme> <variant>   e.g. "ml4w dark"
#   2) <theme>             e.g. "ml4w-minimal" (single-level theme with style.css at theme root)
#
# Examples:
#   waybar-switch-theme ml4w dark
#   waybar-switch-theme ml4w-minimal

if [[ $# -lt 1 ]]; then
  echo "Usage: $(basename "$0") <theme> [variant]" >&2
  exit 1
fi

theme="$1"
variant="${2:-}"

if [[ -n "$variant" ]]; then
  combo="${theme}/${variant}"
else
  combo="${theme}"  # single-level theme (e.g. ml4w-minimal)
fi

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

