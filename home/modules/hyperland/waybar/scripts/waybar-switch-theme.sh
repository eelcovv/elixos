#!/usr/bin/env bash
set -euo pipefail
# English comment: Switch Waybar theme using ONLY symlinks.
# English comment: Supports two modes:
# English comment:   1) Family + Variant exists  -> active -> ~/.config/waybar/<variant>/
# English comment:   2) No variant (or 'base')   -> active -> ~/.config/waybar/  (top-level)
# English comment: Waybar must start with: -s ~/.config/waybar/active/style.css

usage() { echo "Usage: $(basename "$0") <family> [<variant>|base]"; exit 2; }

[[ $# -ge 1 ]] || usage
FAMILY="$1"
VARIANT="${2:-base}"   # 'base' means: no variant shim, point active to top-level

WB="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
THEMES="$WB/themes"

FAMILY_CFG="$THEMES/$FAMILY/config.jsonc"
FAMILY_CSS="$THEMES/$FAMILY/style.css"
VARIANT_CSS="$THEMES/$FAMILY/$VARIANT/style.css"

# English comment: validate family base files from the store-backed tree
[[ -f "$FAMILY_CFG" ]] || { echo "Missing: $FAMILY_CFG" >&2; exit 3; }
[[ -f "$FAMILY_CSS" ]] || { echo "Missing: $FAMILY_CSS" >&2; exit 3; }

# English comment: top-level symlinks to the family base (for ../style.css in variants)
ln -sfn "$FAMILY_CFG" "$WB/config.jsonc"
ln -sfn "$FAMILY_CSS" "$WB/style.css"

if [[ "$VARIANT" != "base" && -f "$VARIANT_CSS" ]]; then
  # ---------------- Variant mode ----------------
  # English comment: prepare local variant shim so relative paths resolve
  mkdir -p "$WB/$VARIANT"
  ln -sfn "$VARIANT_CSS"   "$WB/$VARIANT/style.css"   # main variant css
  ln -sfn "$WB/colors.css" "$WB/$VARIANT/colors.css"  # @import "colors.css"
  ln -sfn "$WB/themes"     "$WB/$VARIANT/themes"      # url("themes/assets/...")

  # English comment: atomically point active -> variant directory
  ln -sfn "$WB/$VARIANT" "$WB/active"

  MODE="variant"
  TARGET="$WB/active/style.css  (../style.css -> $WB/style.css)"
else
  # ---------------- Base mode -------------------
  # English comment: no variant (or explicit 'base'): make active -> top-level
  # English comment: Waybar will load $WB/style.css directly; it should be self-contained
  ln -sfn "$WB" "$WB/active"

  MODE="base"
  TARGET="$WB/active/style.css  (= $WB/style.css)"
fi

echo "Switched to: family='$FAMILY' variant='${VARIANT:-base}' mode=$MODE"
echo "Config: $WB/config.jsonc"
echo "CSS   : $TARGET"

# English comment: fast restart
pkill waybar || true
waybar -l trace -c "$WB/config.jsonc" -s "$WB/active/style.css" >/dev/null 2>&1 &
disown || true