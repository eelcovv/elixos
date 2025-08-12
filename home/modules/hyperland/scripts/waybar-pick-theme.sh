
#!/usr/bin/env bash
# shellcheck shell=bash
set -euo pipefail

WB_DIR="$HOME/.config/waybar"
THEMES_DIR="$WB_DIR/themes"

declare -a paths names

# Enumerate variants that have CSS (skip "assets")
while IFS= read -r -d '' css_file; do
    variant_dir="$(dirname "$css_file")"
    rel="${variant_dir#"$THEMES_DIR"/}"            # -> ml4w/dark
    label=""
    if [[ -f "$variant_dir/config.sh" ]]; then
        # shellcheck source=/dev/null
        source "$variant_dir/config.sh" || true
        label="${theme_name:-}"
    fi
    [[ -z "$label" ]] && label="$(printf "%s — %s" "${rel%%/*}" "${rel##*/}")"
    names+=("$label")
    paths+=("$rel")
done < <(find "$THEMES_DIR" -mindepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -print0)

if [[ ${#paths[@]} -eq 0 ]]; then
    notify-send "Waybar" "No theme variants found under $THEMES_DIR"
    exit 1
fi

idx="$(printf "%s\n" "${names[@]}" | rofi -dmenu -i -no-show-icons -width 40 -p 'Waybar theme' -format i || true)"
[[ -z "$idx" || ! "$idx" =~ ^[0-9]+$ ]] && exit 0

exec waybar-switch-theme "${paths[$idx]}"
