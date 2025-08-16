#!/usr/bin/env bash
# Single-list theme picker for Waybar.
# Toont alle themes + varianten in één menu (rofi → wofi → fzf).
# Vereist: helper-functions.sh met list_themes en switch_theme.

set -euo pipefail

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

# --- Picker helper (rofi default) --------------------------------------------
menu_pick() {
  # Args: <prompt>; Output: selected line to stdout
  local prompt="$1"
  local picker="${WAYBAR_PICKER:-auto}"

  if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    echo "ERROR: No DISPLAY or WAYLAND_DISPLAY; are you in a GUI session?" >&2
    return 1
  fi

  case "$picker" in
    rofi)
      rofi -dmenu -p "$prompt" -i
      ;;
    wofi)
      wofi --dmenu --prompt="$prompt"
      ;;
    fzf)
      fzf --prompt "$prompt> "
      ;;
    auto)
      if command -v rofi >/dev/null 2>&1; then
        rofi -dmenu -p "$prompt" -i
      elif command -v wofi >/dev/null 2>&1; then
        wofi --dmenu --prompt="$prompt"
      elif command -v fzf >/dev/null 2>&1; then
        fzf --prompt "$prompt> "
      else
        echo "ERROR: No picker found (install rofi/wofi/fzf or set WAYBAR_PICKER)" >&2
        return 1
      fi
      ;;
  esac
}

# --- Bouw één lijst via helper:list_themes ------------------------------------
# list_themes geeft items zoals:
#   default
#   ml4w/
#   ml4w/dark
#   ml4w/light
# We willen géén “mapjes” (entries die eindigen op /) selecteerbaar maken.
if ! command -v list_themes >/dev/null 2>&1; then
  echo "ERROR: list_themes not found (helper incomplete?)" >&2
  exit 1
fi

# Verzamel en filter
mapfile -t ENTRIES < <(list_themes | grep -v '/$' | sort -u)

if [[ ${#ENTRIES[@]} -eq 0 ]]; then
  echo "No themes found (did your themes directory get detected by the helper?)." >&2
  exit 1
fi

# --- Toon menu & pas toe ------------------------------------------------------
SEL="$(printf '%s\n' "${ENTRIES[@]}" | menu_pick "Waybar theme")" || true
if [[ -z "${SEL:-}" ]]; then
  echo "No selection made." >&2
  exit 1
fi

# switch_theme accepteert zowel "family" als "family/variant"
switch_theme "$SEL"

