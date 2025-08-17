#!/usr/bin/env bash
# Robust Waybar theme switcher (Hyprland is the single "chef").
# - Resolves themes from ~/.config/waybar/themes
# - Builds in a temp dir, validates JSON (if jq is available)
# - Merges style.css + style-custom.css
# - Flattens CSS custom properties `var(--...)` using colors.css or safe defaults
# - Atomically replaces ~/.config/waybar/current/*
# - Sends USR2 only (no start/stop): Hyprland should start Waybar

set -euo pipefail

# ----- debug helpers ----------------------------------------------------------
log()   { printf '%s\n' "$*"; }
debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

# ----- paths ------------------------------------------------------------------
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
CUR="$CFG/current"

usage() {
  echo "usage: waybar-switch-theme <theme> [variant] | <theme/variant>" >&2
  exit 2
}

# ----- parse args: support 'theme/variant' or 'theme variant' -----------------
theme=""; variant=""
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
    theme="$1"; variant="$2"
    ;;
  *)
    usage
    ;;
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
  # escape string for safe sed replacement
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\//\\/}
  s=${s//&/\\&}
  printf '%s' "$s"
}

flatten_css_vars() {
  # flatten_css_vars <infile> <outfile> [colors.css]
  # Replaces var(--name) with values from colors.css if present,
  # otherwise uses sane defaults to avoid Waybar crash.
  local in="$1" out="$2" colors="${3:-}"
  local tmp="$out.tmp"
  cp -f "$in" "$tmp"

  declare -A cmap=()

  # Defaults to keep bar usable even if theme doesn't provide colors.css
  cmap[fg]="#d0d0d0"
  cmap[bg]="#202020"
  cmap[background]="#202020"
  cmap[text]="#d0d0d0"
  cmap[primary]="#5e81ac"
  cmap[accent]="#5e81ac"
  cmap[warning]="#ebcb8b"
  cmap[urgent]="#bf616a"
  cmap[good]="#a3be8c"
  cmap[bad]="#bf616a"

  # Parse :root { --name: value; } definitions if colors.css exists
  if [[ -n "$colors" && -f "$colors" ]]; then
    # shellcheck disable=SC2016
    while IFS='=' read -r k v; do
      [[ -n "$k" && -n "$v" ]] || continue
      # Trim value
      v="${v%%;*}"; v="${v//[$'\t\r\n ']/}"
      cmap["$k"]="$v"
    done < <(awk '
      match($0,/--([a-zA-Z0-9_-]+)\s*:\s*([^;]+);/,m){print m[1] "=" m[2]}
    ' "$colors")
  fi

  # Replace known vars
  for name in "${!cmap[@]}"; do
    val="${cmap[$name]}"
    val_esc=$(sed_escape "$val")
    sed -E -i "s/var\\(--${name}\\)/${val_esc}/g" "$tmp"
  done
  # Replace any remaining var(--something) with a neutral default to prevent crashes
  sed -E -i 's/var\(--[a-zA-Z0-9_-]+\)/#d0d0d0/g' "$tmp"

  mv -f "$tmp" "$out"
}

# Minimal, valid fallbacks (only used if theme lacks these files)
MIN_CONFIG='{
  "layer": "top",
  "position": "top",
  "height": 32,
  "modules-center": ["clock"],
  "clock": { "format": "{:%H:%M}" }
}'
MIN_MODULES='{}'
# CSS here must be plain GTK CSS (no CSS custom properties)
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

# Style: start with base style (or minimal), then append style-custom.css if present,
# then flatten CSS vars using colors.css (if any), otherwise use safe defaults.
if [[ -n "${src_style:-}" ]]; then
  install -Dm0644 "$src_style" "$tmpdir/style.resolved.css"
else
  printf '%s\n' "$MIN_STYLE" > "$tmpdir/style.resolved.css"
fi
if [[ -n "${src_style_custom:-}" ]]; then
  cat "$src_style_custom" >> "$tmpdir/style.resolved.css"
fi

# Flatten var(--...) if present
if grep -q 'var(' "$tmpdir/style.resolved.css"; then
  debug "flatten: replacing CSS var(--...) using colors.css='${src_colors:-<none>}'"
  flatten_css_vars "$tmpdir/style.resolved.css" "$tmpdir/style.resolved.css" "${src_colors:-}"
fi

# Colors / modules / config (use fallbacks if missing)
if [[ -n "${src_colors:-}" ]]; then
  install -Dm0644 "$src_colors" "$tmpdir/colors.css"
else
  printf '/* no colors.css provided by theme */\n' > "$tmpdir/colors.css"
fi

if [[ -n "${src_modules:-}" ]]; then
  install -Dm0644 "$src_modules" "$tmpdir/modules.jsonc"
else
  printf '%s\n' "$MIN_MODULES" > "$tmpdir/modules.jsonc"
fi

if [[ -n "${src_config:-}" ]]; then
  install -Dm0644 "$src_config" "$tmpdir/config.jsonc"
else
  printf '%s\n' "$MIN_CONFIG" > "$tmpdir/config.jsonc"
fi

# ----- validate JSON if jq is available --------------------------------------
if have_cmd jq; then
  if ! jq -e . "$tmpdir/config.jsonc" >/dev/null 2>&1; then
    log "ERROR: config.jsonc is invalid JSON; aborting switch."
    exit 1
  fi
  if ! jq -e . "$tmpdir/modules.jsonc" >/dev/null 2>&1; then
    log "ERROR: modules.jsonc is invalid JSON; aborting switch."
    exit 1
  fi
else
  debug "jq not found; skipping JSON validation"
fi

# ----- atomically replace current/ -------------------------------------------
mkdir -p "$CFG"
# Replace directory in one go to avoid partial file states
if [[ -d "$CUR" ]]; then
  rm -rf "$CUR"
fi
mv "$tmpdir" "$CUR"
# Tempdir now moved; cancel trap to avoid accidental delete
trap - EXIT

# Safety net: ensure entrypoint symlinks exist (HM usually does this already)
ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

# ----- reload only (Hyprland should manage the process) ----------------------
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -USR2 -x waybar || true
else
  log "Note: Waybar is not running. Hyprland should start it via exec-once."
fi

log "Waybar theme: Applied: ${theme}${variant:+/$variant}"

