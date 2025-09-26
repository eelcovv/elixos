#!/usr/bin/env bash
# Switch Waybar family + variant via symlinks and restart safely,
# even when invoked from a Waybar custom module.
# Usage: waybar-switch-theme <family> [variant]
set -euo pipefail

FAMILY="${1:-ml4w-blur}"
VARIANT="${2:-light}"

CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
FAM_DIR="$CFG/themes/$FAMILY"

# --- Early self-detach if launched from Waybar -----------------------------
# If our parent is 'waybar', re-exec detached so killing Waybar won't kill us too.
parent_comm="$(ps -o comm= -p "${PPID:-1}" 2>/dev/null || true)"
if printf '%s' "$parent_comm" | grep -q '^waybar$'; then
  if command -v systemd-run >/dev/null 2>&1; then
    systemd-run --user --quiet --collect --unit=waybar-switch \
      "$0" "$@"
  else
    setsid -f "$0" "$@" >/dev/null 2>&1 </dev/null
  fi
  exit 0
fi

# --- Helpers ---------------------------------------------------------------
kill_loose_waybar() {
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -TERM -x waybar || true
    for _ in $(seq 1 20); do
      pgrep -x waybar >/dev/null 2>&1 || return 0
      sleep 0.05
    done
    pkill -KILL -x waybar || true
  fi
}

has_service() {
  systemctl --user list-unit-files | grep -q '^waybar-managed\.service'
}

service_active() {
  systemctl --user is-active --quiet waybar-managed
}

# --- Validate --------------------------------------------------------------
if [ ! -d "$FAM_DIR" ]; then
  echo "Unknown family: $FAMILY" >&2
  exit 1
fi

# --- Update symlinks -------------------------------------------------------
# 1) current -> chosen family
ln -sfnT "$FAM_DIR" "$CFG/current"

# 2) active -> variant dir if present, else the family dir
if [ -d "$CFG/current/$VARIANT" ]; then
  ln -sfnT "$CFG/current/$VARIANT" "$CFG/active"
else
  ln -sfnT "$CFG/current" "$CFG/active"
fi

# 3) Top-level config.jsonc -> family's config (if provided)
if [ -f "$CFG/current/config.jsonc" ]; then
  ln -sfn "$CFG/current/config.jsonc" "$CFG/config.jsonc"
fi

# 4) Top-level style.css -> family's base style (optional convenience)
if [ -f "$CFG/current/style.css" ]; then
  ln -sfn "$CFG/current/style.css" "$CFG/style.css"
fi

# 5) Ensure colors.css visible from active (variant > family > global)
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
  # Simply restart the managed service (clean & robust)
  systemctl --user restart waybar-managed || true
  echo "waybar-managed.service restarted"
else
  # No managed service: kill any foreground instances, then start detached
  kill_loose_waybar
  if command -v systemd-run >/dev/null 2>&1; then
    systemd-run --user --quiet --collect --unit=waybar-relaunch \
      waybar -l info -c "$CFG/config.jsonc" -s "$CFG/active/style.css"
  else
    setsid -f bash -lc "waybar -l info -c '$CFG/config.jsonc' -s '$CFG/active/style.css' >/dev/null 2>&1" </dev/null
  fi
  echo "Standalone Waybar started"
fi

