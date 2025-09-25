#!/usr/bin/env bash
# waybar-switch-theme: switch Waybar theme by moving symlinks only.
# - Updates ~/.config/waybar/current and ~/.config/waybar/config
# - Service uses CSS from ~/.config/waybar/current/style.css
# - After switching, we do a hard restart of the user service for reliability.

set -euo pipefail

: "${WAYBAR_DIR:=$HOME/.config/waybar}"
: "${THEMES_DIR:=$WAYBAR_DIR/themes}"
: "${SERVICE:=waybar-managed.service}"
: "${DEBUG:=0}"

# DEBUG=0 silent, 1 logs, 2 xtrace
[ "$DEBUG" = "2" ] && set -x
log(){ [ "$DEBUG" = "1" ] && printf 'DEBUG: %s\n' "$*" >&2 || true; }
die(){ printf 'ERROR: %s\n' "$*" >&2; exit 1; }

usage() {
  echo "Usage: $(basename "$0") <family>[/<variant>]  or  <family> <variant>"
  echo "Examples:"
  echo "  $(basename "$0") ml4w-blur"
  echo "  $(basename "$0") ml4w-blur light"
}

# Parse args
if [ $# -eq 0 ]; then usage; exit 1; fi
if [ $# -ge 2 ]; then SEL="$1/$2"; else SEL="$1"; fi

family="${SEL%%/*}"
variant=""
[ "$SEL" != "$family" ] && variant="${SEL#*/}"

# Sanity
[ -d "$WAYBAR_DIR" ] || die "Waybar dir not found: $WAYBAR_DIR"
[ -d "$THEMES_DIR" ] || die "Themes dir not found: $THEMES_DIR"

family_dir="$THEMES_DIR/$family"
[ -d "$family_dir" ] || die "Theme family not found: $family ($family_dir)"

# Determine target directory and ensure CSS exists
target="$family_dir"
if [ -n "$variant" ]; then
  [ -d "$family_dir/$variant" ] || die "Variant not found: $family/$variant"
  [ -f "$family_dir/$variant/style.css" ] || die "Variant CSS missing: $family/$variant/style.css"
  target="$family_dir/$variant"
else
  [ -f "$family_dir/style.css" ] || die "Base CSS missing: $family_dir/style.css"
fi

# Set ~/.config/waybar/current -> target directory
current_link="$WAYBAR_DIR/current"
if [ -e "$current_link" ] && [ ! -L "$current_link" ]; then rm -rf "$current_link"; fi
ln -sfn "$target" "$current_link"
log "current -> $target"

# Set ~/.config/waybar/config -> target's config(.jsonc) if present, else fallback to family root
cfg_link="$WAYBAR_DIR/config"
if   [ -f "$target/config.jsonc" ]; then
  ln -sfn "$target/config.jsonc" "$cfg_link"
  log "config -> $target/config.jsonc"
elif [ -f "$target/config" ]; then
  ln -sfn "$target/config" "$cfg_link"
  log "config -> $target/config"
elif [ -f "$family_dir/config.jsonc" ]; then
  ln -sfn "$family_dir/config.jsonc" "$cfg_link"
  log "config -> $family_dir/config.jsonc (family fallback)"
elif [ -f "$family_dir/config" ]; then
  ln -sfn "$family_dir/config" "$cfg_link"
  log "config -> $family_dir/config (family fallback)"
else
  die "No config(.jsonc) found in $target or $family_dir"
fi

# Hard restart for reliability (avoid reload ambiguity)
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user restart "$SERVICE" >/dev/null 2>&1 || true

# Verify it's up; if not, print last logs to help debugging
if ! systemctl --user is-active --quiet "$SERVICE"; then
  echo "Waybar service failed to start after theme switch. Recent logs:" >&2
  journalctl --user -u "$SERVICE" -n 80 --no-pager >&2 || true
  exit 1
fi

printf 'Waybar theme switched to: %s\n' "$SEL"

