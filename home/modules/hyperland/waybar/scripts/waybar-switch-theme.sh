#!/usr/bin/env bash
# waybar-switch-theme: move only ~/.config/waybar/current, never config.
# Also ensure a colors.css exists for themes that @import it.

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

# args
if [ $# -eq 0 ]; then usage; exit 1; fi
if [ $# -ge 2 ]; then SEL="$1/$2"; else SEL="$1"; fi

family="${SEL%%/*}"
variant=""
[ "$SEL" != "$family" ] && variant="${SEL#*/}"

# sanity
[ -d "$WAYBAR_DIR" ] || die "Waybar dir not found: $WAYBAR_DIR"
[ -d "$THEMES_DIR" ] || die "Themes dir not found: $THEMES_DIR"

family_dir="$THEMES_DIR/$family"
[ -d "$family_dir" ] || die "Theme family not found: $family ($family_dir)"

# determine target directory and ensure CSS exists
target="$family_dir"
if [ -n "$variant" ]; then
  [ -d "$family_dir/$variant" ] || die "Variant not found: $family/$variant"
  [ -f "$family_dir/$variant/style.css" ] || die "Variant CSS missing: $family/$variant/style.css"
  target="$family_dir/$variant"
else
  [ -f "$family_dir/style.css" ] || die "Base CSS missing: $family_dir/style.css"
fi

# set ~/.config/waybar/current -> target
current_link="$WAYBAR_DIR/current"
if [ -e "$current_link" ] && [ ! -L "$current_link" ]; then rm -rf "$current_link"; fi
ln -sfn "$target" "$current_link"
log "current -> $target"

# guarantee a colors.css is present where theme expects it
# If the theme/variant lacks colors.css, symlink one to our fallback in WAYBAR_DIR.
if [ ! -e "$current_link/colors.css" ]; then
  ln -sfn "$WAYBAR_DIR/colors.css" "$current_link/colors.css"
  log "colors.css -> $WAYBAR_DIR/colors.css (fallback)"
fi

# hard restart for reliability
systemctl --user daemon-reload >/dev/null 2>&1 || true
systemctl --user restart "$SERVICE" >/dev/null 2>&1 || true

# verify
if ! systemctl --user is-active --quiet "$SERVICE"; then
  echo "Waybar failed to start after theme switch. Recent logs:" >&2
  journalctl --user -u "$SERVICE" -n 80 --no-pager >&2 || true
  exit 1
fi

printf 'Waybar theme switched to: %s\n' "$SEL"