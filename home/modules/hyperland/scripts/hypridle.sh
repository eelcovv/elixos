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

case "${1:-}" in
  # ---- Waybar endpoints ----
  status)
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
    notify "Lock" "hyprlock"
    exec hyprlock
    ;;

  dpms-off)
    notify "DPMS" "off"
    exec hyprctl dispatch dpms off
    ;;

  dpms-on)
    notify "DPMS" "on"
    exec hyprctl dispatch dpms on
    ;;

  suspend)
    notify "Suspend" "systemctl suspend"
    exec systemctl suspend
    ;;

  *)
    echo "usage: $(basename "$0") {status|toggle|lock|dpms-off|dpms-on|suspend}" >&2
    exit 2
    ;;
esac

