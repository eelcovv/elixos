#!/usr/bin/env bash
set -euo pipefail
# English comment: Pick a <family>/<variant> (or family/base) grouped by family.
# English comment: Sorts by family, then puts 'base' first, then variants alphabetically.

WB="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
SW="${WAYBAR_SWITCH_BIN:-$HOME/.local/bin/waybar-switch-theme}"
command -v "$SW" >/dev/null 2>&1 || { echo "Missing: $SW" >&2; exit 1; }

list_variants() {
  # depth 3: themes/<family>/<variant>/style.css (include symlinks)
  find "$WB/themes" -mindepth 3 -maxdepth 3 \( -type f -o -type l \) -name style.css \
    | sed -E "s|$WB/themes/||; s|/style\.css$||"
}

list_families_with_base() {
  # depth 2: themes/<family>/style.css (include symlinks) -> emit <family>/base
  find "$WB/themes" -mindepth 2 -maxdepth 2 \( -type f -o -type l \) -name style.css \
    -printf '%h\n' | sed -E "s|$WB/themes/||" | awk '{print $0"/base"}'
}

list_entries() {
  # all variants + base entries
  {
    list_variants
    list_families_with_base
  } | sort -u
}

sort_grouped() {
  # group by family; put 'base' first within each family; variants alphabetically after
  awk -F'/' '{
    fam=$1; var=$2;
    key_var = (var=="base") ? "0" : "1" var;
    printf "%s/%s\t%s\t%s\n", fam, var, fam, key_var
  }' | sort -t$'\t' -k2,2 -k3,3 | cut -f1
}

choose() {
  local entries
  entries="$(list_entries | sort_grouped)"
  if command -v rofi >/dev/null 2>&1; then
    printf '%s\n' "$entries" | rofi -dmenu -p 'Waybar theme' -i
  elif command -v wofi >/dev/null 2>&1; then
    printf '%s\n' "$entries" | wofi --dmenu --prompt='Waybar theme'
  elif command -v fzf >/dev/null 2>&1; then
    printf '%s\n' "$entries" | fzf --prompt 'Waybar theme> '
  else
    printf '%s\n' "$entries" | head -n1
  fi
}

SEL="${1:-}"; [[ -n "$SEL" ]] || SEL="$(choose || true)"
[[ -n "$SEL" ]] || { echo "No selection." >&2; exit 2; }

FAMILY="${SEL%%/*}"
VARIANT="${SEL##*/}"
exec "$SW" "$FAMILY" "$VARIANT"

