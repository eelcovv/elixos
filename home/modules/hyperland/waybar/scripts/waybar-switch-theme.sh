#!/usr/bin/env bash
# Switch Waybar family + variant via symlinks and restart cleanly.
# Usage: waybar-switch-theme <family> [variant]
set -euo pipefail

FAMILY="${1:-ml4w-blur}"
VARIANT="${2:-light}"

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
FAM_DIR="$CFG/themes/$FAMILY"

# --- Helpers ---------------------------------------------------------------

# Kill all non-systemd Waybar processes and wait until they're gone
kill_loose_waybar() {
  # Send SIGTERM to all waybar PIDs (if any), then wait briefly; escalate if needed
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -TERM -x waybar || true
    for _ in $(seq 1 20); do
      if ! pgrep -x waybar >/dev/null 2>&1; then
        return 0
      fi
      sleep 0.05
    done
    # Still running? send SIGKILL
    pkill -KILL -x waybar || true
  fi
}

# Does the user service exist?
has_service() {
  systemctl --user list-unit-files | grep -q '^waybar-managed\.service'
}

# Is the user service active?
service_active() {
  systemctl --user is-active --quiet waybar-managed
}

# --- Validate inputs -------------------------------------------------------

if [ ! -d "$FAM_DIR" ]; then
  echo "Unknown family: $FAMILY" >&2
  exit 1
fi

# --- Update symlinks -------------------------------------------------------

# 1) current -> family
ln -sfnT "$FAM_DIR" "$CFG/current"

# 2) active -> current/<variant> (or current if variant dir is missing)
if [ -d "$CFG/current/$VARIANT" ]; then
  ln -sfnT "$CFG/current/$VARIANT" "$CFG/active"
else
  ln -sfnT "$CFG/current" "$CFG/active"
fi

# 3) top-level style.css -> family base style
if [ -f "$CFG/current/style.css" ]; then
  ln -sfn "$CFG/current/style.css" "$CFG/style.css"
fi

# 4) ensure colors.css for active (variant > family > fallback)
if [ ! -e "$CFG/active/colors.css" ]; then
  if [ -e "$CFG/current/colors.css" ]; then
    ln -sfn "$CFG/current/colors.css" "$CFG/active/colors.css"
  elif [ -e "$CFG/colors.css" ]; then
    ln -sfn "$CFG/colors.css" "$CFG/active/colors.css"
  fi
fi

echo "Switched to family='$FAMILY' variant='${VARIANT}'"

# --- Clean restart logic ---------------------------------------------------

if has_service; then
  # Stop the systemd service first to avoid it respawning during pkill
  if service_active; then
    systemctl --user stop waybar-managed || true
  fi
  # Kill any stray/old foreground Waybar instances
  kill_loose_waybar
  # Start the managed service fresh
  systemctl --user start waybar-managed
  echo "waybar-managed.service restarted"
else
  # No managed service: ensure no leftovers, then start one foreground instance
  kill_loose_waybar
  nohup env WAYBAR_LOG_LEVEL=trace \
    waybar -l trace -c "$CFG/config.jsonc" -s "$CFG/active/style.css" \
    >/dev/null 2>&1 &
  disown
  echo "Standalone Waybar started"
fi

