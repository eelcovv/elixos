#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

WB_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES_DIR="$WB_DIR/themes"
SETTINGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/settings/waybar-theme.sh"
SWITCHER="${HOME}/.local/bin/waybar-switch-theme"

mkdir -p "$(dirname "$SETTINGS_FILE")"

# --- helpers ---------------------------------------------------------------

slug_to_title() {
  # "ml4w-blur" -> "Ml4w Blur"
  local s="$1"
  s="${s//-/ }"
  awk '{
    for(i=1;i<=NF;i++){
      $i=toupper(substr($i,1,1)) tolower(substr($i,2))
    }
    print
  }' <<<"$s"
}

discover_label() {
  # Args: <theme> <variant> <dir>
  local theme="$1" variant="$2" dir="$3" label=""

  # 1) "theme_name" uit config.jsonc in variant of theme-root
  if [[ -f "$dir/config.jsonc" ]]; then
    label="$(sed -n 's/.*"theme_name"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' "$dir/config.jsonc" | head -n1 || true)"
  fi
  if [[ -z "$label" && -f "$THEMES_DIR/$theme/config.jsonc" ]]; then
    label="$(sed -n 's/.*"theme_name"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' "$THEMES_DIR/$theme/config.jsonc" | head -n1 || true)"
  fi

  # 2) Comment in style.css: /* Theme: ... */
  if [[ -z "$label" && -f "$dir/style.css" ]]; then
    label="$(sed -n 's@.*[/][*][[:space:]]*Theme:[[:space:]]*\(.*\)[[:space:]]*[*]/.*@\1@p' "$dir/style.css" | head -n1 || true)"
  fi

  # 3) Fallback: "<Theme Title>" of "<Theme Title> — <Variant Title>"
  if [[ -z "$label" ]]; then
    if [[ -n "$variant" ]]; then
      label="$(printf "%s — %s" "$(slug_to_title "$theme")" "$(slug_to_title "$variant")")"
    else
      label="$(slug_to_title "$theme")"
    fi
  fi

  printf '%s' "$label"
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "Missing dependency: $1" >&2; exit 1; }; }

# --- collect themes/varianten ----------------------------------------------

declare -a PATHS NAMES
declare -A SEEN

# 1) Variants: themes/<theme>/<variant>/style.css (of style-custom.css)
while IFS= read -r -d '' css; do
  dir="$(dirname "$css")"                          # .../themes/<theme>/<variant>
  rel="${dir#"$THEMES_DIR"/}"                      # <theme>/<variant>
  theme="${rel%%/*}"
  variant="${rel#*/}"

  # dedupe
  key="v:$rel"
  [[ -n "${SEEN[$key]:-}" ]] && continue
  SEEN[$key]=1

  label="$(discover_label "$theme" "$variant" "$dir")"
  PATHS+=("/$theme;/$theme/$variant")
  NAMES+=("$label")
done < <(find "$THEMES_DIR" -mindepth 2 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -print0 | sort -z)

# 2) Root-level themes: themes/<theme>/style.css (zonder varianten)
while IFS= read -r -d '' css; do
  dir="$(dirname "$css")"                          # .../themes/<theme>
  theme="${dir##*/}"
  variant=""

  # sla over als er varianten bestaan (die dekken deze theme al af)
  if find "$dir" -mindepth 2 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) | grep -q .; then
    continue
  fi

  key="t:$theme"
  [[ -n "${SEEN[$key]:-}" ]] && continue
  SEEN[$key]=1

  label="$(discover_label "$theme" "$variant" "$dir")"
  PATHS+=("/$theme;/$theme")   # consistent formaat voor SETTINGS_FILE
  NAMES+=("$label")
done < <(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -print0 | sort -z)

# Abort als niets gevonden
if [[ ${#PATHS[@]} -eq 0 ]]; then
  notify-send "Waybar" "No themes found under $THEMES_DIR"
  exit 1
fi

# --- menu & selectie --------------------------------------------------------

need rofi
choice_idx="$(printf "%s\n" "${NAMES[@]}" | rofi -dmenu -i -no-show-icons -width 44 -p "Waybar theme" -format i || true)"
[[ -z "$choice_idx" || ! "$choice_idx" =~ ^[0-9]+$ ]] && exit 0

selected="${PATHS[$choice_idx]}"
echo "$selected" > "$SETTINGS_FILE"
echo ":: Selected theme: $selected"

# Parse naar call
base="${selected%%;*}"; base="${base#/}"          # theme
full="${selected##*;}";  full="${full#/}"          # theme of theme/variant

# --- apply ------------------------------------------------------------------

# Prefer direct call naar je switcher (sneller, geen extra launchers nodig)
if [[ -x "$SWITCHER" ]]; then
  if [[ "$full" == */* ]]; then
    "$SWITCHER" "$full"        # theme/variant
  else
    "$SWITCHER" "$base"        # alleen theme
  fi
else
  # Fallback: minimal reload
  systemctl --user reload waybar-managed.service 2>/dev/null || systemctl --user restart waybar-managed.service || true
fi

notify-send "Waybar Theme" "Applied: ${NAMES[$choice_idx]}"

