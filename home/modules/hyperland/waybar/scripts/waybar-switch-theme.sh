#!/usr/bin/env bash
# Switch Waybar family + variant via symlinks en herstart.
# Usage: waybar-switch-theme <family> [variant]
set -euo pipefail

FAMILY="${1:-ml4w-blur}"
VARIANT="${2:-light}"

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
FAM_DIR="$CFG/themes/$FAMILY"

if [ ! -d "$FAM_DIR" ]; then
  echo "Unknown family: $FAMILY" >&2
  exit 1
fi

# 1) current -> family
ln -sfnT "$FAM_DIR" "$CFG/current"

# 2) active -> current/<variant> (of current als variantmap ontbreekt)
if [ -d "$CFG/current/$VARIANT" ]; then
  ln -sfnT "$CFG/current/$VARIANT" "$CFG/active"
else
  ln -sfnT "$CFG/current" "$CFG/active"
fi

# 3) top-level style.css -> family base style
if [ -f "$CFG/current/style.css" ]; then
  ln -sfn "$CFG/current/style.css" "$CFG/style.css"
fi

# 4) colors.css zekerstellen voor active (variant > family > fallback)
if [ ! -e "$CFG/active/colors.css" ]; then
  if [ -e "$CFG/current/colors.css" ]; then
    ln -sfn "$CFG/current/colors.css" "$CFG/active/colors.css"
  elif [ -e "$CFG/colors.css" ]; then
    ln -sfn "$CFG/colors.css" "$CFG/active/colors.css"
  fi
fi

echo "Switched to family='$FAMILY' variant='${VARIANT}'"

# 5) Restart Waybar:
# - If the Managed Service exists and runs: Restart it
# - Otherwize: Kill Loose Waybar and Start Foreground with right paths
if systemctl --user list-units --type=service --all | grep -q "^waybar-managed\.service"; then
  echo "Restarting waybar-managed.service"
  systemctl --user restart waybar-managed
else
  echo "Restarting waybar"
  pkill -x waybar || true
  WAYBAR_LOG_LEVEL=trace \
  waybar -l trace -c "$CFG/config.jsonc" -s "$CFG/active/style.css" >/dev/null 2>&1 &
  disown
fi

