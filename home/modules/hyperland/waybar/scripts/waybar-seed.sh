#!/usr/bin/env bash
# waybar-seed.sh — Bootstrap ~/.config/waybar/current from your themes
# Safe to run multiple times (idempotent).

set -euo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$CFG/themes"
CUR="$CFG/current"

log() { printf '[seed] %s\n' "$*" >&2; }
pick_first_file() { for f in "$@"; do [[ -f "$f" ]] && { printf '%s\n' "$f"; return 0; }; done; return 1; }

mkdir -p "$CFG" "$CUR"

# Pick a reasonable initial variant
choose_variant() {
  if [[ -f "$THEMES/default/style.css" ]]; then
    echo "default"; return 0
  fi
  local first
  first="$(find -L "$THEMES" -mindepth 2 -maxdepth 2 -type f -name 'style.css' | head -n1 || true)"
  if [[ -n "$first" ]]; then
    # Strip prefix/suffix → "family/variant"
    echo "${first#"$THEMES/"}" | sed 's#/style\.css$##'
    return 0
  fi
  echo ""; return 1
}

variant="$(choose_variant || true)"
if [[ -z "$variant" ]]; then
  # Minimal fallback so Waybar can start even if no themes are present
  log "No theme variant with style.css found. Writing minimal placeholders."
  printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
  printf '{ "modules-left": [], "modules-center": [], "modules-right": [] }\n' > "$CUR/config.jsonc"
  printf '{}\n' > "$CUR/modules.jsonc"
  : > "$CUR/colors.css"
else
  log "Selected variant: $variant"
  var_dir="$THEMES/$variant"
  theme_dir="${var_dir%/*}"   # themes/<family>

  # colors.css cascade: variant → theme → global → empty
  if col="$(pick_first_file "$var_dir/colors.css" "$theme_dir/colors.css" "$CFG/colors.css")"; then
    ln -sfn "$col" "$CUR/colors.css"
    log "colors.css → $col"
  else
    : > "$CUR/colors.css"
    log "colors.css → empty (none found)"
  fi

  # config.jsonc cascade: variant → theme → default → minimal
  if cfg="$(pick_first_file "$var_dir/config.jsonc" "$theme_dir/config.jsonc" "$THEMES/default/config.jsonc")"; then
    ln -sfn "$cfg" "$CUR/config.jsonc"
    log "config.jsonc → $cfg"
  else
    printf '{ "modules-left": [], "modules-center": [], "modules-right": [] }\n' > "$CUR/config.jsonc"
    log "config.jsonc → minimal"
  fi

  # modules.jsonc cascade: variant → theme → global → {}
  if mods="$(pick_first_file "$var_dir/modules.jsonc" "$theme_dir/modules.jsonc" "$CFG/modules.jsonc")"; then
    ln -sfn "$mods" "$CUR/modules.jsonc"
    log "modules.jsonc → $mods"
  else
    printf '{}\n' > "$CUR/modules.jsonc"
    log "modules.jsonc → {}"
  fi

  # style.resolved.css = colors import + flattened CSS (strip nested imports)
  css_src=""
  if   [[ -f "$var_dir/style.css" ]]; then css_src="$var_dir/style.css"
  elif [[ -f "$var_dir/style-custom.css" ]]; then css_src="$var_dir/style-custom.css"
  elif [[ -f "$theme_dir/style.css" ]]; then css_src="$theme_dir/style.css"
  elif [[ -f "$theme_dir/style-custom.css" ]]; then css_src="$theme_dir/style-custom.css"
  fi

  if [[ -n "$css_src" ]]; then
    tmp="$(mktemp)"
    printf '@import url("colors.css");\n' > "$tmp"
    sed -E '/@import.*\.\.\/style\.css/d; /@import.*colors\.css/d' "$css_src" >> "$tmp"
    mv -f "$tmp" "$CUR/style.resolved.css"
    log "style.resolved.css built from $css_src"
  else
    printf '@import url("colors.css");\n' > "$CUR/style.resolved.css"
    log "style.resolved.css → only colors import (no css_src)"
  fi
fi

# Force top-level entry points to current/* so Waybar always reads from there
ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"
log "Entrypoints symlinked to current/*"

# Hot-reload if Waybar is already running (do NOT start a second instance)
if pgrep -f '(^|/)\.?waybar(-wrapped)?([[:space:]]|$)' >/dev/null 2>&1; then
  pkill -USR2 waybar || true
  log "Waybar hot-reload (USR2) sent"
fi

log "Seed done."

