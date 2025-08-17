#!/usr/bin/env bash
set -euo pipefail

# ---- debug helper -----------------------------------------------------------
log()   { printf '%s\n' "$*"; }
debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

# ---- paths ------------------------------------------------------------------
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
CUR="$CFG/current"

usage() { echo "usage: waybar-switch-theme <theme> [variant] | <theme/variant>" >&2; exit 2; }

# ---- args: support 'theme/variant' or 'theme variant' -----------------------
theme=""; variant=""
case "$#" in
  1)  if [[ "$1" == */* ]]; then theme="${1%%/*}"; variant="${1#*/}"; else theme="$1"; fi ;;
  2)  theme="$1"; variant="$2" ;;
  *)  usage ;;
esac
[[ -n "$theme" ]] || usage

theme_dir="$THEMES/$theme"
var_dir="$theme_dir/${variant:-}"
def_dir="$THEMES/default"

debug "resolve: theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"

# ---- helpers ----------------------------------------------------------------
first_existing() {
  for p in "$@"; do [[ -f "$p" ]] && { echo "$p"; return 0; }; done
  return 1
}

safe_write() {
  # safe_write <content> <dest>  (writes literal content)
  local content="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  printf '%s\n' "$content" > "$dest"
}

# Minimal, geldige defaults (alleen als theme niets aanbiedt)
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

# ---- resolve bronnen UITSLUITEND uit themes/ --------------------------------
src_style="$(first_existing "$var_dir/style.css" "$theme_dir/style.css" "$def_dir/style.css" || true)"
src_style_custom="$(first_existing "$var_dir/style-custom.css" "$theme_dir/style-custom.css" || true)"
src_colors="$(first_existing "$var_dir/colors.css" "$theme_dir/colors.css" "$def_dir/colors.css" || true)"
src_modules="$(first_existing "$var_dir/modules.jsonc" "$theme_dir/modules.jsonc" "$def_dir/modules.jsonc" || true)"
src_config="$(first_existing "$var_dir/config.jsonc" "$theme_dir/config.jsonc" "$def_dir/config.jsonc" || true)"

if [[ -z "${src_style:-}" ]]; then
  log "ERROR: no style.css in $var_dir or $theme_dir or $def_dir"
  exit 1
fi

# ---- bouw nieuwe current in tmp dir -----------------------------------------
tmp="$(mktemp -d "${CFG//\//_}.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

# CSS (met optionele custom append)
if [[ -n "${src_style:-}" ]]; then
  install -Dm0644 "$src_style" "$tmp/style.resolved.css"
else
  safe_write "$MIN_STYLE" "$tmp/style.resolved.css"
fi
[[ -n "${src_style_custom:-}" ]] && cat "$src_style_custom" >> "$tmp/style.resolved.css"

# kleuren / modules / config
if [[ -n "${src_colors:-}" ]]; then install -Dm0644 "$src_colors" "$tmp/colors.css"; else safe_write "$MIN_COLORS" "$tmp/colors.css"; fi
if [[ -n "${src_modules:-}" ]]; then install -Dm0644 "$src_modules" "$tmp/modules.jsonc"; else safe_write "$MIN_MODULES" "$tmp/modules.jsonc"; fi
if [[ -n "${src_config:-}" ]]; then install -Dm0644 "$src_config" "$tmp/config.jsonc"; else safe_write "$MIN_CONFIG" "$tmp/config.jsonc"; fi

# ---- JSON-validatie ----------------------------------------------------------
if ! jq -e . "$tmp/config.jsonc" >/dev/null 2>&1; then
  log "ERROR: config.jsonc is invalid JSON; aborting switch (bar blijft draaien)."
  exit 1
fi
if ! jq -e . "$tmp/modules.jsonc" >/dev/null 2>&1; then
  log "ERROR: modules.jsonc is invalid JSON; aborting switch."
  exit 1
fi

# ---- atomisch vervangen van current/* ---------------------------------------
mkdir -p "$CFG"
mkdir -p "$CUR"
rsync -a --delete "$tmp/" "$CUR/"

# Entrypoint-symlinks (door HM hook of hier als safety net)
ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

# ---- probeer nette reload; geen start/stop (Hyprland is de chef) ------------
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -USR2 -x waybar || true
else
  log "Note: Waybar is not running. Hyprland should start it via exec-once."
fi

log "Waybar theme: Applied: ${theme}${variant:+/$variant}"

