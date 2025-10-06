#!/usr/bin/env bash
set -euo pipefail
# English: Show family-only for base-only themes, and family/variant for themes with variants.
# English: Group by family, put base first, then variants alphabetically.

WB="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
SW="${WAYBAR_SWITCH_BIN:-$HOME/.local/bin/waybar-switch-theme}"
command -v "$SW" >/dev/null 2>&1 || { echo "Missing: $SW" >&2; exit 1; }

list_variants() {
  # depth=3: themes/<family>/<variant>/style.css (include symlinks)
  find "$WB/themes" -mindepth 3 -maxdepth 3 \( -type f -o -type l \) -name style.css \
    | sed -E "s|$WB/themes/||; s|/style\.css$||"
}

list_families_base_only() {
  # Families that have a top-level style.css (depth=2) BUT NO variant style.css (depth=3)
  mapfile -t fam_with_base < <(
    find "$WB/themes" -mindepth 2 -maxdepth 2 \( -type f -o -type l \) -name style.css \
      -printf '%h\n' | sed -E "s|$WB/themes/||" | sort -u
  )
  mapfile -t fam_with_variants < <(
    list_variants | cut -d/ -f1 | sort -u
  )

  # print families that have base but no variants
  if ((${#fam_with_base[@]})); then
    printf '%s\n' "${fam_with_base[@]}" \
      | { if ((${#fam_with_variants[@]})); then grep -vxF -f <(printf '%s\n' "${fam_with_variants[@]}"); else cat; fi; }
  fi
}

list_entries() {
  # Output lines like:
  #   family/variant    (for families with variants)
  #   family            (for base-only families)
  list_variants
  list_families_base_only
}

sort_grouped() {
  # Group by family; show bare 'family' first, then 'family/variant' alphabetically
  awk -F'/' '{
    fam=$1; var=($2==""?"":$2);
    if (var=="") { key="0"; out=$0; } else { key="1" var; out=$0; }
    print out "\t" fam "\t" key;
  }' | sort -t$'\t' -k2,2 -k3,3 | cut -f1
}

choose() {
  local entries
  entries="$(list_entries | sort -u | sort_grouped)"
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

SEL="${1:-}"
[[ -n "$SEL" ]] || SEL="$(choose || true)"
[[ -n "$SEL" ]] || { echo "No selection." >&2; exit 2; }

# Map selection to switcher args:
# - "family/variant" -> FAMILY=family VARIANT=variant
# - "family"         -> FAMILY=family VARIANT=base
if [[ "$SEL" == */* ]]; then
  FAMILY="${SEL%%/*}"
  VARIANT="${SEL##*/}"
else
  FAMILY="$SEL"
  VARIANT="base"
fi

exec "$SW" "$FAMILY" "$VARIANT"

