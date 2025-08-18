#!/usr/bin/env bash
# Waybar theme switcher (Hyprland is the single "chef")
# - Resolves themes from ~/.config/waybar/themes
# - Recursively inlines CSS @import files (from variant/theme/default dirs)
# - Flattens CSS var(--...) using colors.css or safe defaults (GTK CSS has no var())
# - Atomically replaces ~/.config/waybar/current/*
# - Sends USR2 to the actual Waybar process (no start/stop here)

set -euo pipefail

# ---- debug helpers -----------------------------------------------------------
log()   { printf '%s\n' "$*"; }
debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

# ---- paths -------------------------------------------------------------------
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
CUR="$CFG/current"

usage() { echo "usage: waybar-switch-theme <theme> [variant] | <theme/variant>" >&2; exit 2; }

# ---- parse args --------------------------------------------------------------
theme=""; variant=""
case "$#" in
  1) if [[ "$1" == */* ]]; then theme="${1%%/*}"; variant="${1#*/}"; else theme="$1"; fi ;;
  2) theme="$1"; variant="$2" ;;
  *) usage ;;
esac
[[ -n "$theme" ]] || usage

theme_dir="$THEMES/$theme"
var_dir="$theme_dir/${variant:-}"
def_dir="$THEMES/default"

debug "resolve: theme_dir=$theme_dir var_dir=$var_dir def_dir=$def_dir"

# ---- helpers -----------------------------------------------------------------
first_existing() {
  for p in "$@"; do [[ -f "$p" ]] && { echo "$p"; return 0; }; done
  return 1
}

sed_escape() {
  local s=$1; s=${s//\\/\\\\}; s=${s//\//\\/}; s=${s//&/\\&}; printf '%s' "$s"
}

# inline_css_imports <infile> <outfile> <search_dir1> <search_dir2> <search_dir3>
# Recursively inlines @import "file.css"; or @import url(file.css);
inline_css_imports() {
  local in="$1" out="$2"; shift 2
  local -a search_dirs=("$@")
  local tmp="$(mktemp)"
  cp -f "$in" "$tmp"

  # Limit recursion to prevent cycles
  local max_passes=10
  local pass=0
  while grep -Eq '^\s*@import[[:space:]]' "$tmp" && [[ $pass -lt $max_passes ]]; do
    pass=$((pass+1))
    local next="$(mktemp)"
    : > "$next"
    # Read line-by-line; replace @import with file contents if found
    while IFS= read -r line; do
      if [[ "$line" =~ ^[[:space:]]*@import[[:space:]] ]]; then
        # extract path between quotes or url(...)
        local path
        path="$(printf '%s\n' "$line" | sed -nE 's/.*@import[[:space:]]+url\(([^)]+)\).*/\1/p')"
        if [[ -z "$path" ]]; then
          path="$(printf '%s\n' "$line" | sed -nE 's/.*@import[[:space:]]+["'\'']([^"'\'']+)["'\''].*/\1/p')"
        fi
        # strip quotes if any
        path="${path%\"}"; path="${path#\"}"; path="${path%\'}"; path="${path#\'}"
        # resolve candidate
        local found=""
        if [[ -n "$path" ]]; then
          if [[ "$path" == /* ]]; then
            [[ -f "$path" ]] && found="$path"
          else
            for d in "${search_dirs[@]}"; do
              [[ -n "$d" && -f "$d/$path" ]] && { found="$d/$path"; break; }
            done
            # as last resort, look relative to CFG (e.g. "colors.css")
            [[ -z "$found" && -f "$CFG/$path" ]] && found="$CFG/$path"
          fi
        fi
        if [[ -n "$found" ]]; then
          cat "$found" >> "$next"
        else
          # skip unknown import (do not keep the line)
          :
        fi
      else
        printf '%s\n' "$line" >> "$next"
      fi
    done < "$tmp"
    mv -f "$next" "$tmp"
  done

  mv -f "$tmp" "$out"
}

# flatten_css_vars <infile> <outfile> [colors.css]
flatten_css_vars() {
  local in="$1" out="$2" colors="${3:-}"
  local tmp="$out.tmp"; cp -f "$in" "$tmp"

  declare -A cmap=()
  # defaults
  cmap[fg]="#d0d0d0"; cmap[bg]="#202020"; cmap[background]="#202020"; cmap[text]="#d0d0d0"
  cmap[primary]="#5e81ac"; cmap[accent]="#5e81ac"; cmap[warning]="#ebcb8b"
  cmap[urgent]="#bf616a";  cmap[good]="#a3be8c";  cmap[bad]="#bf616a"

  if [[ -n "$colors" && -f "$colors" ]]; then
    # parse --name: value;
    while IFS='=' read -r k v; do
      [[ -n "$k" && -n "$v" ]] || continue
      v="${v%%;*}"; v="${v//[$'\t\r\n ']/}"
      cmap["$k"]="$v"
    done < <(awk 'match($0,/--([a-zA-Z0-9_-]+)\s*:\s*([^;]+);/,m){print m[1] "=" m[2]}' "$colors")
  fi

  for name in "${!cmap[@]}"; do
    local val="${cmap[$name]}"; local val_esc; val_esc=$(sed_escape "$val")
    sed -E -i "s/var\\(--${name}\\)/${val_esc}/g" "$tmp"
  done
  # neutral fallback for any leftover var()
  sed -E -i 's/var\(--[a-zA-Z0-9_-]+\)/#d0d0d0/g' "$tmp"

  mv -f "$tmp" "$out"
}

# minimal fallbacks
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

# ---- resolve sources ---------------------------------------------------------
src_style="$(first_existing "$var_dir/style.css" "$theme_dir/style.css" "$def_dir/style.css" || true)"
src_style_custom="$(first_existing "$var_dir/style-custom.css" "$theme_dir/style-custom.css" || true)"
src_colors="$(first_existing "$var_dir/colors.css" "$theme_dir/colors.css" "$def_dir/colors.css" || true)"
src_modules="$(first_existing "$var_dir/modules.jsonc" "$theme_dir/modules.jsonc" "$def_dir/modules.jsonc" || true)"
src_config="$(first_existing "$var_dir/config.jsonc" "$theme_dir/config.jsonc" "$def_dir/config.jsonc" || true)"

if [[ -z "${src_style:-}" ]]; then
  log "ERROR: no style.css found in: $var_dir, $theme_dir, or $def_dir"
  exit 1
fi

# ---- build temp tree ---------------------------------------------------------
tmpdir="$(mktemp -d "${CFG//\//_}.build.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

# Compose CSS: base + custom -> inline imports -> flatten vars
if [[ -n "${src_style:-}" ]]; then
  install -Dm0644 "$src_style" "$tmpdir/style.resolved.css"
else
  printf '%s\n' "$MIN_STYLE" > "$tmpdir/style.resolved.css"
fi
[[ -n "${src_style_custom:-}" ]] && cat "$src_style_custom" >> "$tmpdir/style.resolved.css"

# Inline @import recursively from variant/theme/default (then CFG)
inline_css_imports "$tmpdir/style.resolved.css" "$tmpdir/style.resolved.css" "$var_dir" "$theme_dir" "$def_dir" "$CFG"

# Flatten var(--...) after imports are inlined (so variables & uses are in one file)
if grep -q 'var(' "$tmpdir/style.resolved.css"; then
  debug "flatten: using colors.css='${src_colors:-<none>}'"
  flatten_css_vars "$tmpdir/style.resolved.css" "$tmpdir/style.resolved.css" "${src_colors:-}"
fi

# Other files
if [[ -n "${src_colors:-}"  ]]; then install -Dm0644 "$src_colors"  "$tmpdir/colors.css";    else printf '/* no colors.css */\n' > "$tmpdir/colors.css"; fi
if [[ -n "${src_modules:-}" ]]; then install -Dm0644 "$src_modules" "$tmpdir/modules.jsonc"; else printf '%s\n' "$MIN_MODULES" > "$tmpdir/modules.jsonc"; fi
if [[ -n "${src_config:-}"  ]]; then install -Dm0644 "$src_config"  "$tmpdir/config.jsonc";  else printf '%s\n' "$MIN_CONFIG"  > "$tmpdir/config.jsonc";  fi

# ---- atomically replace current/ --------------------------------------------
mkdir -p "$CFG"
[[ -d "$CUR" ]] && rm -rf "$CUR"
mv "$tmpdir" "$CUR"
trap - EXIT

# Entrypoints (safety net; HM doet dit meestal al)
ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

# ---- reload Waybar zonder onszelf te raken ----------------------------------
# exact procesnaam; GEEN -f (anders raak je dit script)
pkill -USR2 -x waybar 2>/dev/null || true

log "Waybar theme: Applied: ${theme}${variant:+/$variant}"

