#!/usr/bin/env bash
# Waybar theme helper — direct write (no "current", no symlinks to current)
# Copies theme's config.jsonc/style.css into ~/.config/waybar/,
# overlays variant (if any), normalizes style.css imports,
# preserves colors.css (Matugen-owned), ensures include JSONs exist,
# reloads Waybar.

set -euo pipefail

# --- Paths --------------------------------------------------------------------
WAYBAR_DIR="${WAYBAR_DIR:-$HOME/.config/waybar}"                 # -> ~/.config/waybar
WAYBAR_THEMES_DIR="${WAYBAR_THEMES_DIR:-$WAYBAR_DIR/themes}"     # -> ~/.config/waybar/themes
DEFAULT_FAMILY="${DEFAULT_FAMILY:-default}"

_debug() { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && echo "DEBUG: $*" >&2; }
_die()   { echo "ERROR: $*" >&2; exit 1; }

_copy_if_exists() { # _copy_if_exists SRC DEST
  local src="$1" dest="$2"
  [[ -f "$src" ]] || return 1
  install -Dm0644 -- "$src" "$dest"
}

_replace_symlink_with_file() { # _replace_symlink_with_file DEST [fallback]
  local dest="$1" fallback="${2:-}"
  if [[ -L "$dest" ]]; then
    local src_real; src_real="$(readlink -f -- "$dest" || true)"
    rm -f -- "$dest"
    if [[ -n "$src_real" && -f "$src_real" ]]; then
      install -Dm0644 -- "$src_real" "$dest"
    elif [[ -n "$fallback" ]]; then
      printf '%s\n' "$fallback" >"$dest"; chmod 0644 "$dest"
    else
      : >"$dest"; chmod 0644 "$dest"
    fi
  fi
}

# Normalize CSS:
# - always prepend: @import url("colors.css");
# - drop any @import that references colors.css again
# - drop any @import that starts with "~/" (GTK won't expand tilde)
_normalize_style_css() {
  local css="$1"
  [[ -f "$css" ]] || return 0
  local tmp="$css.tmp"
  {
    printf '@import url("colors.css");\n'
    # keep everything except imports of colors.css or tilde paths
    awk '
      BEGIN{IGNORECASE=1}
      {
        # trim leading spaces
        line=$0
        # match @import (case-insensitive)
        if (match(line, /^[[:space:]]*@import[[:space:]]+url\(([^)]+)\)/, m)) {
          raw=m[1]; gsub(/["'\'']/, "", raw)
          # drop if points to colors.css (any path) or starts with "~/"
          if (raw ~ /(^|\/)colors\.css$/ || raw ~ /^~\//) next
        }
        print $0
      }' "$css"
  } > "$tmp"
  mv -f -- "$tmp" "$css"
}

_ensure_includes_exist() { # _ensure_includes_exist CONFIG_JSONC
  local cfg_json="$1"
  [[ -f "$cfg_json" ]] || return 0
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
        */waybar-quicklinks.json) printf '[]\n' >"$abspath" ;;
        *)                        printf '{}\n' >"$abspath" ;;
      esac
      chmod 0644 "$abspath"
    fi
  done
}

_reload_waybar() {
  if systemctl --user is-active --quiet waybar-managed.service; then
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
  else
    pkill -USR2 -x waybar 2>/dev/null || true
  fi
}

# --- Public API ---------------------------------------------------------------
# Resolve absolute path for the switcher once.
_waybar_switch_bin() {
  # Allow override via env
  if [[ -n "${WAYBAR_SWITCH:-}" && -x "${WAYBAR_SWITCH}" ]]; then
    printf '%s\n' "$WAYBAR_SWITCH"
    return 0
  fi
  # Common locations
  local cands=(
    "$HOME/.local/bin/waybar-switch-theme"
    "/run/current-system/sw/bin/waybar-switch-theme"
    "/usr/local/bin/waybar-switch-theme"
    "/usr/bin/waybar-switch-theme"
  )
  for c in "${cands[@]}"; do
    [[ -x "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  # Last resort: PATH
  if command -v waybar-switch-theme >/dev/null 2>&1; then
    command -v waybar-switch-theme
    return 0
  fi
  echo "ERROR: waybar-switch-theme not found (set WAYBAR_SWITCH to an absolute path)" >&2
  return 1
}

# Resolve absolute path for the switcher once.
_waybar_switch_bin() {
  # Allow override via env
  if [[ -n "${WAYBAR_SWITCH:-}" && -x "${WAYBAR_SWITCH}" ]]; then
    printf '%s\n' "$WAYBAR_SWITCH"
    return 0
  fi
  # Common locations
  local cands=(
    "$HOME/.local/bin/waybar-switch-theme"
    "/run/current-system/sw/bin/waybar-switch-theme"
    "/usr/local/bin/waybar-switch-theme"
    "/usr/bin/waybar-switch-theme"
  )
  for c in "${cands[@]}"; do
    [[ -x "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  # Last resort: PATH
  if command -v waybar-switch-theme >/dev/null 2>&1; then
    command -v waybar-switch-theme
    return 0
  fi
  echo "ERROR: waybar-switch-theme not found (set WAYBAR_SWITCH to an absolute path)" >&2
  return 1
}

switch_theme() {
  local sel="${1:-}"
  if [[ -z "$sel" ]]; then
    echo "switch_theme: missing selection (family or family/variant)" >&2
    return 2
  fi
  local sw; sw="$(_waybar_switch_bin)" || return 3
  # Call the switcher with the selection; ensure non-interactive, quiet unless you want debug
  WAYBAR_THEME_DEBUG="${WAYBAR_THEME_DEBUG:-0}" "$sw" "$sel"
}


list_themes() {
  local base="$WAYBAR_THEMES_DIR" fam vdir
  while IFS= read -r -d '' famdir; do
    fam="$(basename "$famdir")"
    [[ "$fam" == .* ]] && continue
    [[ "$fam" == assets ]] && continue
    local root_has=""
    [[ -f "$famdir/style.css" || -f "$famdir/style-custom.css" ]] && root_has=1
    local any_var=0
    while IFS= read -r -d '' vdir; do
      [[ -f "$vdir/style.css" || -f "$vdir/style-custom.css" ]] || continue
      if [[ -z "$root_has" && $any_var -eq 0 ]]; then printf '%s/\n' "$fam"; fi
      printf '%s/%s\n' "$fam" "$(basename "$vdir")"
      any_var=1
    done < <(find -L "$famdir" -mindepth 1 -maxdepth 1 -type d -print0)
    [[ -n "$root_has" ]] && printf '%s\n' "$fam"
  done < <(find -L "$base" -mindepth 1 -maxdepth 1 -type d -print0)
}

