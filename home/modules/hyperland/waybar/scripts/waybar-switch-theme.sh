#!/usr/bin/env bash
# waybar-switch-theme (symlink-only, no file writes)
set -euo pipefail

: "${WAYBAR_DIR:=$HOME/.config/waybar}"
: "${THEMES_DIR:=$WAYBAR_DIR/themes}"
: "${SERVICE:=waybar-managed.service}"
: "${DEBUG:=0}"

[ "$DEBUG" = "2" ] && set -x
log(){ [ "$DEBUG" = "1" ] && printf 'DEBUG: %s\n' "$*" >&2 || true; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  echo "Usage: $(basename "$0") <family>[/<variant>]  or  <family> <variant>"
  echo "Examples:"
  echo "  $(basename "$0") ml4w-blur"
  echo "  $(basename "$0") ml4w-blur light"
}

# --- args parsing ---
if [ $# -eq 0 ]; then usage; exit 1; fi
if [ $# -ge 2 ]; then SEL="$1/$2"; else SEL="$1"; fi

family="${SEL%%/*}"
variant=""; [ "$SEL" != "$family" ] && variant="${SEL#*/}"

# --- sanity checks ---
[ -d "$WAYBAR_DIR" ]   || die "Waybar dir not found: $WAYBAR_DIR"
[ -d "$THEMES_DIR" ]   || die "Themes dir not found: $THEMES_DIR"

family_dir="$THEMES_DIR/$family"
[ -d "$family_dir" ]   || die "Theme family not found: $family ($family_dir)"

# Prefer variant style if requested, else family root style.css must exist
base_css="$family_dir/style.css"
var_css=""
if [ -n "$variant" ]; then
  [ -d "$family_dir/$variant" ] || die "Variant not found: $family/$variant"
  [ -f "$family_dir/$variant/style.css" ] || die "Variant CSS missing: $family/$variant/style.css"
  var_css="$family_dir/$variant/style.css"
else
  [ -f "$base_css" ] || die "Base CSS missing: $base_css"
fi

# --- switch 'current' symlink to selected target ---
# We make 'current' point directly to the chosen directory:
# - with variant:  ~/.config/waybar/themes/<family>/<variant>
# - without:       ~/.config/waybar/themes/<family>
target="$family_dir"
[ -n "$variant" ] && target="$family_dir/$variant"

# Replace any existing file/dir/symlink at current
current="$WAYBAR_DIR/current"
if [ -e "$current" ] && [ ! -L "$current" ]; then
  # existing directory or file → remove it first
  rm -rf "$current"
fi
ln -sfn "$target" "$current"
log "current -> $target"

# --- make 'config' symlink follow the selected target (config.jsonc or config) ---
cfg_link="$WAYBAR_DIR/config"
cfg_jsonc="$target/config.jsonc"
cfg_plain="$target/config"
if [ -f "$cfg_jsonc" ]; then
  ln -sfn "$cfg_jsonc" "$cfg_link"
  log "config -> $cfg_jsonc"
elif [ -f "$cfg_plain" ]; then
  ln -sfn "$cfg_plain" "$cfg_link"
  log "config -> $cfg_plain"
else
  # if neither exists, keep current config link if present; otherwise error (Waybar needs a config)
  if [ ! -L "$cfg_link" ]; then
    die "No config(.jsonc) in $target and no existing $cfg_link link to keep."
  else
    log "No config in $target; keeping existing $(readlink -f "$cfg_link")"
  fi
fi

# --- reload / restart Waybar cleanly ---
if systemctl --user is-active --quiet "$SERVICE"; then
  systemctl --user reload-or-restart "$SERVICE" >/dev/null 2>&1 || true
else
  # fallback: try to start service, otherwise signal a running waybar
  systemctl --user start "$SERVICE" >/dev/null 2>&1 || \
    pkill -USR2 -x waybar >/dev/null 2>&1 || true
fi

printf 'Waybar theme switched to: %s\n' "$SEL"

