#!/usr/bin/env bash
# Unified hypridle helper:
# - Waybar:   hypridle.sh status | toggle
# - Hooks:    hypridle.sh lock | dpms-off | dpms-on | suspend
set -euo pipefail

# ---- helper + notify fallback ----
HELPER="$HOME/.config/hypr/scripts/helper-functions.sh"
if [[ -r "$HELPER" ]]; then
  # shellcheck disable=SC1090
  source "$HELPER" || true
fi
if [[ "$(type -t notify 2>/dev/null)" != "function" ]]; then
  notify() { printf '%s: %s\n' "hypridle" "$*"; }
fi

has_systemd_service() {
  systemctl --user list-unit-files hypridle.service >/dev/null 2>&1
}

is_running() {
  if has_systemd_service; then
    systemctl --user is-active --quiet hypridle.service
  else
    pgrep -x hypridle >/dev/null 2>&1
  fi
}

start_hypridle() {
  if has_systemd_service; then
    systemctl --user start hypridle.service
  else
    nohup hypridle >/dev/null 2>&1 &
  fi
}

stop_hypridle() {
  if has_systemd_service; then
    systemctl --user stop hypridle.service
  else
    pkill -x hypridle >/dev/null 2>&1 || true
  fi
}

# ---- single-instance hyprlock launcher ----
lock_once() {
  # Pause media (failing like no player)
  playerctl --all-players pause >/dev/null 2>&1 || true

  # If Hyprlock is already running: Displays on and ready
  if pgrep -x hyprlock >/dev/null 2>&1; then
    notify "Lock" "hyprlock already running → dpms on"
    hyprctl dispatch dpms on || true
    return 0
  fi

  notify "Lock" "starting hyprlock"
  # Displays so that all monitors draw the lock neatly
  hyprctl dispatch dpms on || true

  # Start Hyprlock in background;no 'exec', otherwise you will end this script
  nohup hyprlock >/dev/null 2>&1 &
}

case "${1:-}" in
  # ---- Waybar endpoints ----
  status)
    # Mini-delay so that status is correct after Toggle
    sleep 0.1
    if is_running; then
      printf '{"text":"RUNNING","class":"active","tooltip":"Screen locking active\nLeft: Deactivate"}\n'
    else
      printf '{"text":"NOT RUNNING","class":"notactive","tooltip":"Screen locking deactivated\nLeft: Activate"}\n'
    fi
    ;;

  toggle)
    if is_running; then
      notify "hypridle" "Stopping"
      stop_hypridle
    else
      notify "hypridle" "Starting"
      start_hypridle
    fi
    ;;

  # ---- Hook actions for hypridle.conf ----
  lock)
    lock_once
    ;;

  dpms-off)
    notify "DPMS" "off"
    hyprctl dispatch dpms off
    ;;

  dpms-on)
    notify "DPMS" "on"
    hyprctl dispatch dpms on
    ;;

  suspend)
    # Lock first, give Hyprlock fraction time to start
    lock_once
    sleep 0.3
    notify "Suspend" "systemctl suspend"
    systemctl suspend
    ;;

  *)
    echo "usage: $(basename "$0") {status|toggle|lock|dpms-off|dpms-on|suspend}" >&2
    exit 2
    ;;
esac

