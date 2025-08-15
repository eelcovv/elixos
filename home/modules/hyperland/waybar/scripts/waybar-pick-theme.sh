#!/usr/bin/env bash
# Two-step picker for Waybar themes:
# 1) Pick a theme family (e.g., "ml4w", "ml4w-minimal", "default")
# 2) If the family has variants (subfolders with style.css), pick one
# 3) Delegate to switch_theme (from helper-functions.sh) with either:
#      - "family/variant" (when a variant was chosen)
#      - "family"         (single-level theme with style.css at family root)
#
# Notes:
# - Excludes non-theme folders like "assets"
# - Works with read-only Nix store symlinks; we only read files
# - Menu order preference: wofi → rofi → fzf → stdin fallback

set -euo pipefail

# Locate helper (installed path first, dev fallback second)
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

BASE="$HOME/.config/waybar/themes"
if [[ ! -d "$BASE" ]]; then
  echo "No themes dir at $BASE" >&2
  exit 1
fi

menu_pick() {
  # Args: <prompt>; Output: single selected line
  local prompt="$1"
  if command -v wofi >/dev/null 2>&1; then
    wofi --dmenu --prompt="$prompt"
  elif command -v rofi >/dev/null 2>&1; then
    rofi -dmenu -p "$prompt" -i
  elif command -v fzf >/dev/null 2>&1; then
    fzf --prompt "$prompt> "
  else
    # Last-resort fallback: read the first line from stdin
    head -n1
  fi
}

# --- 1) Build list of families that are actual themes ---
FAMILIES=()
# Iterate top-level directories under $BASE (follow symlinks)
while IFS= read -r -d '' famdir; do
  fam="$(basename "$famdir")"
  # Skip hidden dirs and non-theme buckets like "assets"
  [[ "$fam" == .* ]] && continue
  [[ "$fam" == assets ]] && continue

  has_root_style=0
  [[ -f "$famdir/style.css" || -f "$famdir/style-custom.css" ]] && has_root_style=1

  has_variant=0
  # Scan one level of subdirs for style.css / style-custom.css
  shopt -s nullglob
  for vdir in "$famdir"/*/ ; do
    [[ -d "$vdir" ]] || continue
    if [[ -f "$vdir/style.css" || -f "$vdir/style-custom.css" ]]; then
      has_variant=1
      break
    fi
  done
  shopt -u nullglob

  if (( has_root_style == 1 || has_variant == 1 )); then
    FAMILIES+=("$fam")
  fi
done < <(find -L "$BASE" -mindepth 1 -maxdepth 1 -type d -print0)

if [[ ${#FAMILIES[@]} -eq 0 ]]; then
  echo "No theme families with styles found under $BASE" >&2
  exit 1
fi

IFS=$'\n' FAMILIES=( $(printf '%s\n' "${FAMILIES[@]}" | sort -u) ); unset IFS

SEL_FAMILY="$(printf '%s\n' "${FAMILIES[@]}" | menu_pick "Waybar theme")" || true
if [[ -z "${SEL_FAMILY:-}" ]]; then
  echo "No selection made." >&2
  exit 1
fi

FAM_DIR="$BASE/$SEL_FAMILY"
if [[ ! -d "$FAM_DIR" ]]; then
  echo "Invalid theme family: $SEL_FAMILY" >&2
  exit 1
fi

# --- 2) Find variants for this family ---
FILTERED=()
shopt -s nullglob
for vdir in "$FAM_DIR"/*/ ; do
  [[ -d "$vdir" ]] || continue
  if [[ -f "$vdir/style.css" || -f "$vdir/style-custom.css" ]]; then
    FILTERED+=( "$(basename "$vdir")" )
  fi
done
shopt -u nullglob

if [[ ${#FILTERED[@]} -eq 0 ]]; then
  # No variants: fallback to the family root if it has a style.css
  if [[ -f "$FAM_DIR/style.css" || -f "$FAM_DIR/style-custom.css" ]]; then
    switch_theme "$SEL_FAMILY"
    exit 0
  else
    echo "Theme '$SEL_FAMILY' has no variants and no root style.css" >&2
    exit 1
  fi
fi

SEL_VARIANT="$(printf '%s\n' "${FILTERED[@]}" | menu_pick "$SEL_FAMILY variant")" || true
if [[ -z "${SEL_VARIANT:-}" ]]; then
  echo "No selection made." >&2
  exit 1
fi

# --- 3) Switch ---
switch_theme "$SEL_FAMILY/$SEL_VARIANT"

