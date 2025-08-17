#!/usr/bin/env bash
# Robust Waybar theme switcher (Hyprland is the single "chef").
# - Resolves themes from ~/.config/waybar/themes
# - Builds in a temp dir
# - Merges style.css + style-custom.css
# - Flattens CSS custom properties `var(--...)` using colors.css or safe defaults
# - STRIPS any CSS @import lines to avoid Waybar absolute-path issues
# - Atomically replaces ~/.config/waybar/current/*
# - Sends USR2 only (no start/stop): Hyprland should start Waybar
#
# NOTE: Waybar configs in the wild are often JSONC (comments, trailing commas).
#       We DO NOT hard-validate with jq here to avoid false negatives.

set -euo pipefail

# ----- debug helpers ----------------------------------------------------------
log()   { printf '%s\n' "$*"; }
debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

# ----- paths ------------------------------------------------------------------
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
CUR="$CFG/current"

usage() { echo "usage: waybar-switch-theme <theme> [variant] | <theme/variant>" >&2; exit 2; }

# ----- parse args: support 'theme/variant' or 'theme variant' -----------------
theme=""; variant=""
case "$#" in
  1)
    if [[ "$1" == */* ]]; then
      theme="${1%%/*}"; variant="${1#*/}"
    else
      theme="$1"; variant=""
    fi
    ;;
  2) theme="$1"; variant="$2" ;;
  *) usage ;;
esac
[[ -n "$theme" ]] || usage

theme_dir="$THEMES/$theme"
var_dir="$theme_dir/${variant:-}"
def_dir="$THEMES/default"

debug "resolve: theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"

# ----- helpers ----------------------------------------------------------------
first_existing() {
  # echo first existing file from args, else return non-zero
  for p in "$@"; do [[ -f "$p" ]] && { echo "$p"; return 0; }; done
  return 1
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

sed_escape() {
  # escape a string for safe sed replacement
  local s=$1
  s=${s//\\/\\\\}; s=${s//\//\\/}; s=${s//&/\\&}
  printf '%s' "$s"
}

strip_css_imports() {
  # Remove any @import lines to avoid Waybar trying to load weird absolute paths
  sed -E -i '/@import[[:space:]]/d' "$1"
}

flatten_css_vars() {
  # flatten_css_vars <infile> <outfile> [colors.css]
  # Replaces var(--name) with values from colors.css if present,
  # otherwise uses sane defaults to avoid Waybar crash (GTK CSS has no var()).
  local in="$1" out="$2" colors="${3:-}"
  local tmp="$out.tmp"
  cp -f "$in" "$tmp"

  declare -A cmap=()
  # Safe defaults if theme provides no colors.css
  cmap[fg]="#d0d0d0"; cmap[bg]="#202020"
  cmap[background]="#202020"; cmap[text]="#d0d0d0"
  cmap[primary]="#5e81ac"; cmap[accent]="#5e81ac"
  cmap[warning]="#ebcb8b"; cmap[urgent]="#bf616a"
  cmap[good]="#a3be8c";   cmap[bad]="#bf616a"

  if [[ -n "$colors" && -f "$colors" ]]; then
    # Parse :root { --name: value; } definitions
    while IFS='=' read -r k v; do
      [[ -n "$k" && -n "$v" ]] || continue
      v="${v%%;*}"; v="${v//[$'\t\r\n ']/}"
      cmap["$k"]="$v"
    done < <(awk 'match($0,/--([a-zA-Z0-9_-]+)\s*:\s*([^;]+);/,m){print m[1] "=" m[2]}' "$colors")
  fi

  # Replace known vars
  for name in "${!cmap[@]}"; do
    val="${cmap[$name]}"; val_esc=$(sed_escape "$val")
    sed -E -i "s/var\\(--${name}\\)/${val_esc}/g" "$tmp"
  done
  # Replace any remaining var(--something) with a neutral default
  sed -E -i 's/var\(--[a-zA-Z0-9_-]+\)/#d0d0d0/g' "$tmp"

  mv -f "$tmp" "$out"
}

# Minimal, valid fallbacks (no CSS vars)
MIN_CONFIG='{
  "layer": "top",
  "position": "top",
  "height": 32,
  "modules-center": ["clock"],
  "clock": { "format": "{:%H:%M}" }
}'
MIN_MODULES='{}'
MIN_STYLE='* { font-size: 12px; color: #d0d0d0; }
window#waybar { background: #202020; }'

# ----- resolve sources strictly from theme tree -------------------------------
src_style="$(first_existing "$var_dir/style.css" "$theme_dir/style.css" "$def_dir/style.css" || true)"
src_style_custom="$(first_existing "$var_dir/style-custom.css" "$theme_dir/style-custom.css" || true)"
src_colors="$(first_existing "$var_dir/colors.css" "$theme_dir/colors.css" "$def_dir/colors.css" || true)"
src_modules="$(first_existing "$var_dir/modules.jsonc" "$theme_dir/modules.jsonc" "$def_dir/modules.jsonc" || true)"
src_config="$(first_existing "$var_dir/config.jsonc" "$theme_dir/config.jsonc" "$def_dir/config.jsonc" || true)"

if [[ -z "${src_style:-}" ]]; then
  log "ERROR: no style.css found in: $var_dir, $theme_dir, or $def_dir"
  exit 1
fi

# ----- build into a temp dir --------------------------------------------------
tmpdir="$(mktemp -d "${CFG//\//_}.build.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

# Compose CSS: base + optional custom, strip imports, flatten vars
if [[ -n "${src_style:-}" ]]; then
  install -Dm0644 "$src_style" "$tmpdir/style.resolved.css"
else
  printf '%s\n' "$MIN_STYLE" > "$tmpdir/style.resolved.css"
fi
[[ -n "${src_style_custom:-}" ]] && cat "$src_style_custom" >> "$tmpdir/style.resolved.css"

# Strip @import BEFORE/AFTER flatten (belt & suspenders)
strip_css_imports "$tmpdir/style.resolved.css"
if grep -q 'var(' "$tmpdir/style.resolved.css"; then
  debug "flatten: replacing CSS var(--...) using colors.css='${src_colors:-<none>}'"
  flatten_css_vars "$tmpdir/style.resolved.css" "$tmpdir/style.resolved.css" "${src_colors:-}"
  strip_css_imports "$tmpdir/style.resolved.css"
fi

# Other files (with fallbacks)
if [[ -n "${src_colors:-}"  ]]; then install -Dm0644 "$src_colors"  "$tmpdir/colors.css"; else printf '/* no colors.css */\n' > "$tmpdir/colors.css"; fi
if [[ -n "${src_modules:-}" ]]; then install -Dm0644 "$src_modules" "$tmpdir/modules.jsonc"; else printf '%s\n' "$MIN_MODULES" > "$tmpdir/modules.jsonc"; fi
if [[ -n "${src_config:-}"  ]]; then install -Dm0644 "$src_config"  "$tmpdir/config.jsonc";  else printf '%s\n' "$MIN_CONFIG"  > "$tmpdir/config.jsonc";  fi

# ----- (no strict jq-validation; JSONC may contain comments) ------------------
# If you still want a soft check and have jq, you can uncomment this block:
# if have_cmd jq; then
#   jq -e . "$tmpdir/config.jsonc"   >/dev/null || debug "warning: config.jsonc not pure JSON (likely JSONC); skipping strict validation"
#   jq -e . "$tmpdir/modules.jsonc"  >/dev/null || debug "warning: modules.jsonc not pure JSON (likely JSONC); skipping strict validation"
# fi

# ----- atomically replace current/ -------------------------------------------
mkdir -p "$CFG"
[[ -d "$CUR" ]] && rm -rf "$CUR"
mv "$tmpdir" "$CUR"
trap - EXIT

# Entrypoint symlinks (safety net; HM usually ensures these)
ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

# ----- reload only (Hyprland manages lifecycle) ------------------------------
# Always try to send USR2; use -f to match the full cmdline (works even if name differs)
pkill -USR2 -f '[w]aybar' 2>/dev/null || true

log "Waybar theme: Applied: ${theme}${variant:+/$variant}"

