#!/usr/bin/env bash
# ~/.local/bin/hypr-display-watcher
# Watches DRM connector status and auto-applies display profile.
# Requires: inotify-tools (for inotifywait)

set -euo pipefail

SWITCH="${HOME}/.local/bin/hypr-switch-displays"

# Apply on startup to ensure correct profile right away
"${SWITCH}" auto || true

# Helper: list all DRM connector status files (DP/HDMI/eDP)
get_status_files() {
  ls /sys/class/drm/*-{DP,HDMI,eDP}-*/status 2>/dev/null || true
}

# Main loop: re-scan files, then block on inotify until something changes
while true; do
  files=$(get_status_files)
  if [ -z "${files}" ]; then
    # No connectors visible yet; retry later
    sleep 5
    continue
  fi

  # Wait up to 1h for any change; then re-scan (handles hotplug creating/removing files)
  if timeout 1h inotifywait -q -e modify ${files}; then
    # Small debounce since hotplug can emit multiple events
    sleep 0.8
    "${SWITCH}" auto || true
  fi
done
