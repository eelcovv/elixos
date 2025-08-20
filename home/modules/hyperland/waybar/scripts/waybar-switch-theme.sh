#!/usr/bin/env bash
# Waybar theme switcher — direct write (no "current", no symlinks)
# Usage: waybar-switch-theme <theme> [variant] | <theme/variant>
#
# Debug:
#   WAYBAR_THEME_DEBUG=1 waybar-switch-theme ml4w-blur light

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") <theme> [variant] | <theme/variant>" >&2
  exit 2
}

# ---------- parse args ----------
theme=""; variant=""
case "$#" in
  1) if [[ "$1" == */* ]]; then theme="${1%%/*}"; variant="${1#*/}"; else theme="$1"; fi ;;
  2) theme="$1"; variant="$2" ;;
  *) usage ;;
esac
[[ -n "$theme" ]] || usage
combo="${theme}${variant:+/$variant}"

# ---------- paths ----------
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
THEME_DIR="$THEMES/$theme"
VAR_DIR="$THEME_DIR/${variant:-}"

log()   { printf '%s\n' "$*"; }
dbg()   { [[ "${WAYBAR_THEME_DEBUG:-0}" == "1" ]] && printf 'DEBUG: %s\n' "$*" >&2; }
die()   { echo "ERROR: $*" >&2; exit 1; }

[[ -d "$THEME_DIR" ]] || die "Theme not found: $THEME_DIR"
if [[ -n "$variant" && ! -d "$VAR_DIR" ]]; then
  die "Variant not found: $VAR_DIR"
fi

mkdir -p "$CFG"

# ---------- helpers ----------
safe_copy_if_exists() {
  local src="$1" dest="$2" label="${3:-file}"
  if [[ -f "$src" ]]; then
    dbg "copying $label $src → $dest"
    install -Dm0644 -- "$src" "$dest"
    return 0
  fi
  return 1
}

break_symlink_to_file_if_needed() {
  local dest="$1" fallback="${2:-}"
  if [[ -L "$dest" ]]; then
    local src_real; src_real="$(readlink -f -- "$dest" || true)"
    dbg "replacing symlink $dest (→ $src_real)"
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

ensure_includes_exist() {
  # Ensure any "~/.config/*.jsonc" listed in config.jsonc "include" exist
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
    mkdir -p "$(dirname -- "$abspath")"
    [[ -e "$abspath" ]] && continue
    case "$abspath" in
      */waybar-quicklinks.json) printf '[]\n'  >"$abspath" ;;
      *)                        printf '{}\n'  >"$abspath" ;;
    esac
    chmod 0644 "$abspath"
    dbg "created include placeholder: $abspath"
  done
}

merge_styles_variant_then_base() {
  # Build a merged style where variant comes first (defines variables),
  # then base (which may use those variables).
  local out="$1"
  local tmp; tmp="$(mktemp)"; : >"$tmp"

  if [[ -n "$variant" && -f "$VAR_DIR/style.css" ]]; then
    dbg "append VARIANT style: $VAR_DIR/style.css"
    cat "$VAR_DIR/style.css" >>"$tmp"
    echo >>"$tmp"
  fi

  if [[ -f "$THEME_DIR/style.css" ]]; then
    dbg "append BASE style: $THEME_DIR/style.css"
    cat "$THEME_DIR/style.css" >>"$tmp"
  fi

  install -Dm0644 -- "$tmp" "$out"
  rm -f -- "$tmp"
}

normalize_style_css() {
  # Ensure a single colors import at the top.
  # Remove any line that imports colors.css, or imports ../style.css (case-insensitive).
  # Remove any tilde (~) import. Rewrite common asset paths to work from ~/.config/waybar/.
  local css="$1"
  [[ -f "$css" ]] || return 0
  local tmp; tmp="$(mktemp)"

  dbg "normalize: colors import + strip bad imports + rewrite asset paths"
  {
    printf '@import url("colors.css");\n'
    awk '
      {
        line=$0
        ll=tolower(line)

        # Drop colors.css imports (we add a canonical import ourselves)
        if (ll ~ /^[[:space:]]*@import[[:space:]]+/ && index(ll, "colors.css")>0) next

        # Drop any import of ../style.css (variant → parent imports)
        if (ll ~ /^[[:space:]]*@import[[:space:]]+/ && index(ll, "../style.css")>0) next

        # Drop tilde imports (@import "~/...")
        if (ll ~ /^[[:space:]]*@import[[:space:]]+/ && index(ll, "~/")>0) next

        # Rewrite asset paths
        gsub(/\.\.\/\.\.\/assets\//, "themes/assets/", line)
        gsub(/\.\.\/assets\//,       "themes/assets/", line)
        gsub(/url\(\s*["]?\.\.\/assets\//, "url(themes/assets/", line)
        gsub(/url\(\s*["]?\.\/assets\//,   "url(themes/assets/", line)

        print line
      }
    ' "$css"
  } > "$tmp"

  mv -f -- "$tmp" "$css"

  # Final safety: if any ../style.css import survived, strip it now.
  if grep -qiE '^[[:space:]]*@import[[:space:]]+.*\.\./style\.css' "$css"; then
    dbg "normalize: forcing removal of lingering ../style.css import"
    sed -E -i 's/^[[:space:]]*@import[[:space:]]+.*\.\.\/style\.css.*$//I' "$css"
  fi
}

reload_or_start_waybar() {
  if systemctl --user is-active --quiet waybar-managed.service; then
    dbg "reload waybar-managed"
    systemctl --user reload waybar-managed.service || systemctl --user restart waybar-managed.service || true
  else
    dbg "start waybar-managed"
    systemctl --user start waybar-managed.service || true
  fi
}

# ---------- 0) break problematic symlinks ----------
for f in config config.jsonc style.css modules.jsonc colors.css; do
  break_symlink_to_file_if_needed "$CFG/$f"
done

# ---------- 1) copy config/modules (variant overrides base) ----------
if [[ -n "$variant" ]]; then
  safe_copy_if_exists "$VAR_DIR/config.jsonc"  "$CFG/config.jsonc"  "variant config"   || true
  safe_copy_if_exists "$VAR_DIR/modules.jsonc" "$CFG/modules.jsonc" "variant modules"  || true
fi
safe_copy_if_exists "$THEME_DIR/config.jsonc"  "$CFG/config.jsonc"  "base config"      || true
safe_copy_if_exists "$THEME_DIR/modules.jsonc" "$CFG/modules.jsonc" "base modules"     || true

# ---------- 2) merge style: VAR first, then BASE ----------
merge_styles_variant_then_base "$CFG/style.css"

# ---------- 3) normalize CSS ----------
normalize_style_css "$CFG/style.css"

# ---------- 4) ensure colors.css ----------
break_symlink_to_file_if_needed "$CFG/colors.css" '/* default colors (placeholder) */'
if [[ ! -s "$CFG/colors.css" ]]; then
  printf '/* default colors */\n' >"$CFG/colors.css"
  chmod 0644 "$CFG/colors.css"
fi

# ---------- 5) fallbacks ----------
if [[ ! -f "$CFG/config.jsonc" ]]; then
  dbg "write fallback config.jsonc"
  printf '{ "layer":"top", "position":"top", "height":32, "modules-center":["clock"], "clock":{"format":"{:%H:%M}"} }\n' >"$CFG/config.jsonc"
  chmod 0644 "$CFG/config.jsonc"
fi
if [[ ! -f "$CFG/style.css" ]]; then
  dbg "write fallback style.css"
  printf '@import url("colors.css");\nwindow#waybar { background: #202020; }\n* { color: #d0d0d0; font-size: 12px; }\n' >"$CFG/style.css"
  chmod 0644 "$CFG/style.css"
fi
if [[ ! -f "$CFG/modules.jsonc" ]]; then
  dbg "write fallback modules.jsonc"
  printf '{}\n' >"$CFG/modules.jsonc"
  chmod 0644 "$CFG/modules.jsonc"
fi

# ---------- 6) compat symlink & includes ----------
ln -sfn "$CFG/config.jsonc" "$CFG/config"
ensure_includes_exist "$CFG/config.jsonc"

# ---------- 7) reload/start ----------
reload_or_start_waybar

log "Waybar theme: Applied: $combo"

