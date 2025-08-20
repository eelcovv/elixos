_waybar_switch_bin() {
  if [[ -n "${WAYBAR_SWITCH:-}" && -x "${WAYBAR_SWITCH}" ]]; then
    printf '%s\n' "$WAYBAR_SWITCH"; return 0
  fi
  local cands=(
    "$HOME/.local/bin/waybar-switch-theme"
    "/run/current-system/sw/bin/waybar-switch-theme"
    "/usr/local/bin/waybar-switch-theme"
    "/usr/bin/waybar-switch-theme"
  )
  for c in "${cands[@]}"; do
    [[ -x "$c" ]] && { printf '%s\n' "$c"; return 0; }
  done
  if command -v waybar-switch-theme >/dev/null 2>&1; then
    command -v waybar-switch-theme; return 0
  fi
  echo "ERROR: waybar-switch-theme not found (set WAYBAR_SWITCH)" >&2
  return 1
}

switch_theme() {
  local sel="${1:-}"
  [[ -n "$sel" ]] || { echo "switch_theme: missing selection" >&2; return 2; }
  local sw; sw="$(_waybar_switch_bin)" || return 3
  WAYBAR_THEME_DEBUG="${WAYBAR_THEME_DEBUG:-0}" "$sw" "$sel"
}

