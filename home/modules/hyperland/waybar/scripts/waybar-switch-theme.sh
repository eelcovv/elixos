#!/usr/bin/env bash
# Waybar theme switcher with helper fallback
# - Accepts:  waybar-switch-theme <theme> [variant]
#             waybar-switch-theme <theme>/<variant>
# - First tries helper-functions.sh:switch_theme; if not present, falls back
#   to a standalone resolver that builds ~/.config/waybar/current/*
# - Reloads Waybar via systemd (waybar-managed) or SIGUSR2
#
# This version also ensures that any "include" files referenced by the chosen
# config.jsonc exist (creating lightweight placeholders if missing) so Waybar
# never crashes on missing external includes (e.g. ML4W quicklinks).

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <theme> [variant] | <theme/variant>" >&2
  exit 2
}

# -------- parse args ----------------------------------------------------------
theme=""; variant=""
case "${#}" in
  1)
    if [[ "$1" == */* ]]; then theme="${1%%/*}"; variant="${1#*/}"; else theme="$1"; fi
    ;;
  2)
    theme="$1"; variant="$2"
    ;;
  *)
    usage
    ;;
esac
[[ -n "$theme" ]] || usage
combo="${theme}${variant:+/$variant}"

# -------- try helper first ----------------------------------------------------
HELPER_CANDIDATES=(
  "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/helper-functions.sh"
  "$(dirname -- "${BASH_SOURCE[0]}")/helper-functions.sh"
)
for _hf in "${HELPER_CANDIDATES[@]}"; do
  if [[ -r "$_hf" ]]; then
    # shellcheck disable=SC1090
    . "$_hf"
    if type -t switch_theme >/dev/null 2>&1; then
      switch_theme "$combo"
      echo "Waybar theme: Applied via helper: $combo"
      exit 0
    fi
  fi
done

# -------- fallback: standalone implementation --------------------------------
log()   { printf '%s\n' "$*"; }
debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2 || true; }

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
CUR="$CFG/current"

theme_dir="$THEMES/$theme"
var_dir="$theme_dir/${variant:-}"
def_dir="$THEMES/default"

first_existing() {
  for p in "$@"; do [[ -f "$p" ]] && { echo "$p"; return 0; }; done
  return 1
}

sed_escape() {
  local s=$1; s=${s//\\/\\\\}; s=${s//\//\\/}; s=${s//&/\\&}; printf '%s' "$s"
}

# inline_css_imports <infile> <outfile> <search_dir...>
inline_css_imports() {
  local in="$1" out="$2"; shift 2
  local -a search_dirs=("$@")
  local tmp
  tmp="$(mktemp)"
  cp -f "$in" "$tmp"

  local max_passes=10 pass=0
  while grep -Eq '^\s*@import[[:space:]]' "$tmp" && [[ $pass -lt $max_passes ]]; do
    pass=$((pass+1))
    local next; next="$(mktemp)"; : > "$next"
    while IFS= read -r line; do
      if [[ "$line" =~ ^[[:space:]]*@import[[:space:]] ]]; then
        local path found=""
        path="$(printf '%s\n' "$line" | sed -nE 's/.*@import[[:space:]]+url\(([^)]+)\).*/\1/p')"
        [[ -z "$path" ]] && path="$(printf '%s\n' "$line" | sed -nE 's/.*@import[[:space:]]+["'\'']([^"'\'']+)["'\''].*/\1/p')"
        path="${path%\"}"; path="${path#\"}"; path="${path%\'}"; path="${path#\'}"
        if [[ -n "$path" ]]; then
          if [[ "$path" == /* ]]; then
            [[ -f "$path" ]] && found="$path"
          else
            for d in "${search_dirs[@]}"; do
              [[ -n "$d" && -f "$d/$path" ]] && { found="$d/$path"; break; }
            done
            [[ -z "$found" && -f "$CFG/$path" ]] && found="$CFG/$path"
          fi
        fi
        [[ -n "$found" ]] && cat "$found" >> "$next"
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

  declare -A cmap=(
    [fg]="#d0d0d0" [bg]="#202020" [background]="#202020" [text]="#d0d0d0"
    [primary]="#5e81ac" [accent]="#5e81ac" [warning]="#ebcb8b"
    [urgent]="#bf616a"  [good]="#a3be8c"  [bad]="#bf616a"
  )

  if [[ -n "$colors" && -f "$colors" ]]; then
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
  sed -E -i 's/var\(--[a-zA-Z0-9_-]+\)/#d0d0d0/g' "$tmp"

  mv -f "$tmp" "$out"
}

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

src_style="$(first_existing "$var_dir/style.css" "$theme_dir/style.css" "$def_dir/style.css" || true)"
src_style_custom="$(first_existing "$var_dir/style-custom.css" "$theme_dir/style-custom.css" || true)"
src_colors="$(first_existing "$var_dir/colors.css" "$theme_dir/colors.css" "$def_dir/colors.css" || true)"
src_modules="$(first_existing "$var_dir/modules.jsonc" "$theme_dir/modules.jsonc" "$def_dir/modules.jsonc" || true)"
src_config="$(first_existing "$var_dir/config.jsonc" "$theme_dir/config.jsonc" "$def_dir/config.jsonc" || true)"

if [[ -z "${src_style:-}" ]]; then
  log "ERROR: no style.css found in: $var_dir, $theme_dir, or $def_dir"
  exit 1
fi

tmpdir="$(mktemp -d "${CFG//\//_}.build.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

if [[ -n "${src_style:-}" ]]; then
  install -Dm0644 "$src_style" "$tmpdir/style.resolved.css"
else
  printf '%s\n' "$MIN_STYLE" > "$tmpdir/style.resolved.css"
fi
[[ -n "${src_style_custom:-}" ]] && cat "$src_style_custom" >> "$tmpdir/style.resolved.css"

inline_css_imports "$tmpdir/style.resolved.css" "$tmpdir/style.resolved.css" "$var_dir" "$theme_dir" "$def_dir" "$CFG"

if grep -q 'var(' "$tmpdir/style.resolved.css"; then
  flatten_css_vars "$tmpdir/style.resolved.css" "$tmpdir/style.resolved.css" "${src_colors:-}"
fi

if [[ -n "${src_colors:-}"  ]]; then install -Dm0644 "$src_colors"  "$tmpdir/colors.css";    else printf '/* no colors.css */\n' > "$tmpdir/colors.css"; fi
if [[ -n "${src_modules:-}" ]]; then install -Dm0644 "$src_modules" "$tmpdir/modules.jsonc"; else printf '%s\n' "$MIN_MODULES" > "$tmpdir/modules.jsonc"; fi
if [[ -n "${src_config:-}"  ]]; then install -Dm0644 "$src_config"  "$tmpdir/config.jsonc";  else printf '%s\n' "$MIN_CONFIG"  > "$tmpdir/config.jsonc";  fi

mkdir -p "$CFG"
[[ -d "$CUR" ]] && rm -rf "$CUR"
mv "$tmpdir" "$CUR"
trap - EXIT

ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

# --- NEW: ensure required include files exist -------------------------------
# Parse "include" array in config.jsonc and create missing files as placeholders.
ensure_includes() {
  local cfg_json="$1"
  # Collect any "~/.config/...json[ c]" paths in the include array
  mapfile -t includes < <(awk '
    /"include"[[:space:]]*:/,/\]/ {
      while (match($0, /"~\/\.config\/[^"]+\.json[c]?"/)) {
        print substr($0, RSTART+1, RLENGTH-2)
        $0 = substr($0, RSTART+RLENGTH)
      }
    }' "$cfg_json")

  for inc in "${includes[@]}"; do
    local abspath="${inc/#\~/$HOME}"
    local d; d="$(dirname -- "$abspath")"
    mkdir -p "$d"
    if [[ ! -e "$abspath" ]]; then
      case "$abspath" in
        */waybar-quicklinks.json) printf '[]\n' >"$abspath" ;;  # array fits ML4W pattern
        *)                        printf '{}\n' >"$abspath" ;;  # default to empty object
      esac
    fi
  done
}

ensure_includes "$CUR/config.jsonc"
# --- END NEW ----------------------------------------------------------------

# Prefer systemd reload for our unit; otherwise fall back to SIGUSR2
if systemctl --user is-active --quiet waybar-managed.service; then
  systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
else
  pkill -USR2 -x waybar 2>/dev/null || true
fi

log "Waybar theme: Applied: $combo"

