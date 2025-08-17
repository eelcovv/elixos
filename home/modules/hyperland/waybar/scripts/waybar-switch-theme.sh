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
  # install_file <src-or-empty> <dst> <placeholder-contents-if-empty>
  local src="${1:-}" dst="$2" placeholder="${3:-}"
  if [[ -n "$src" ]]; then
    install -Dm0644 "$src" "$dst"
  else
    mkdir -p "$(dirname "$dst")"
    printf '%s\n' "$placeholder" > "$dst"
  fi
}

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
install -Dm0644 "$src_style" "$CUR/style.resolved.css"
if [[ -n "${src_style_custom:-}" ]]; then
  # append custom overrides at the end
  cat "$src_style_custom" >> "$CUR/style.resolved.css"
fi

install_file "$src_colors"  "$CUR/colors.css"   "/* no colors.css for ${theme}${variant:+/$variant} */"
install_file "$src_modules" "$CUR/modules.jsonc" "{/* no modules.jsonc for ${theme}${variant:+/$variant} */}"
install_file "$src_config"  "$CUR/config.jsonc"  "{/* no config.jsonc for ${theme}${variant:+/$variant} */}"

# ---------- refresh entrypoint symlinks AFTER writing current/* ----------
ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

# ---------- reload waybar (ignore if not running) ----------
pkill -USR2 -x waybar 2>/dev/null || true

echo "Waybar theme: Applied: ${theme}${variant:+/$variant}"

