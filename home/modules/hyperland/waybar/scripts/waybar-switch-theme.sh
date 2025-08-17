#!/usr/bin/env bash
set -euo pipefail

debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2 || true; }

BASE="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$BASE/themes"
CFG="$BASE"
CUR="$BASE/current"

usage() {
  echo "usage: waybar-switch-theme <theme> [variant] | <theme/variant>" >&2
  exit 2
}

# -------- parse args (support 'theme variant' and 'theme/variant') ----------
theme=""
variant=""
case "$#" in
  1)
    if [[ "$1" == */* ]]; then
      theme="${1%%/*}"
      variant="${1#*/}"
    else
      theme="$1"
      variant=""
    fi
    ;;
  2)
    theme="$1"
    variant="$2"
    ;;
  *) usage ;;
esac
[[ -n "$theme" ]] || usage

theme_dir="$THEMES/$theme"
var_dir="$theme_dir/${variant:-}"
def_dir="$THEMES/default"

debug "ensure: base=$THEMES token=${theme}${variant:+/$variant}"
debug "_resolve: theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"

# ---------- helpers ----------
first_existing() {
  for p in "$@"; do
    [[ -f "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

install_file() {
  # install_file <src-or-empty> <dst> <fallback-string>
  local src="${1:-}" dst="$2" fallback="${3:-}"
  if [[ -n "$src" ]]; then
    install -Dm0644 "$src" "$dst"
  else
    mkdir -p "$(dirname "$dst")"
    printf '%s\n' "$fallback" > "$dst"
  fi
}

# Veilige minimale placeholders (100% geldige JSON/CSS)
MIN_CONFIG='{
  "layer": "top",
  "position": "top",
  "height": 32,
  "modules-center": ["clock"],
  "clock": { "format": "{:%H:%M}" }
}'
MIN_MODULES='{}'
MIN_COLORS=':root { --fg: #d0d0d0; --bg: #202020; }'
MIN_STYLE='* { font-size: 12px; color: var(--fg); }
window#waybar { background: var(--bg); }'

mkdir -p "$CUR"

# ---------- resolve sources only from theme tree (never from $CFG) ----------
src_style=$(first_existing "$var_dir/style.css" "$theme_dir/style.css" "$def_dir/style.css" || true)
src_style_custom=$(first_existing "$var_dir/style-custom.css" "$theme_dir/style-custom.css" || true)
src_colors=$(first_existing "$var_dir/colors.css" "$theme_dir/colors.css" "$def_dir/colors.css" || true)
src_modules=$(first_existing "$var_dir/modules.jsonc" "$theme_dir/modules.jsonc" "$def_dir/modules.jsonc" || true)
src_config=$(first_existing "$var_dir/config.jsonc" "$theme_dir/config.jsonc" "$def_dir/config.jsonc" || true)

if [[ -z "${src_style:-}" ]]; then
  echo "ERROR: no style.css found in: $var_dir, $theme_dir or $def_dir" >&2
  exit 1
fi

# ---------- write current/* ----------
# CSS
if [[ -n "${src_style:-}" ]]; then
  install -Dm0644 "$src_style" "$CUR/style.resolved.css"
else
  install_file "" "$CUR/style.resolved.css" "$MIN_STYLE"
fi
# append optional custom CSS
if [[ -n "${src_style_custom:-}" ]]; then
  cat "$src_style_custom" >> "$CUR/style.resolved.css"
fi

# colors / modules / config (valide fallbacks)
install_file "$src_colors"  "$CUR/colors.css"   "$MIN_COLORS"
install_file "$src_modules" "$CUR/modules.jsonc" "$MIN_MODULES"
install_file "$src_config"  "$CUR/config.jsonc"  "$MIN_CONFIG"

# ---------- refresh entrypoint symlinks AFTER writing current/* ----------
ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

# ---------- reload waybar; if it died, start it ----------
pkill -USR2 -x waybar 2>/dev/null || true
sleep 0.15
if ! pgrep -x waybar >/dev/null; then
  nohup waybar >/dev/null 2>&1 &
fi

echo "Waybar theme: Applied: ${theme}${variant:+/$variant}"

