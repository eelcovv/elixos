#!/usr/bin/env bash
# Waybar theme picker: single menu with families and variants.
set -euo pipefail

# Ensure ~/.local/bin is in PATH (Hyprland exec can be minimal)
export PATH="$HOME/.local/bin:$PATH"

: "${PICKER_DEBUG:=0}"   # set to 1 to echo debug lines
log() { [ -n "${LOGFILE:-}" ] && printf '%s\n' "$*" >>"$LOGFILE"; }
dbg() { [ "$PICKER_DEBUG" = "1" ] && { echo "[picker] $*"; log "[picker] $*"; } || true; }
die() { echo "ERROR: $*" >&2; log "ERROR: $*"; exit 1; }

# ---------- Try to source helper (optional) ----------
HELPER_CANDIDATES=(
  "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/helper-functions.sh"
  "$(dirname -- "${BASH_SOURCE[0]}")/helper-functions.sh"
)
for f in "${HELPER_CANDIDATES[@]}"; do
  if [[ -r "$f" ]]; then
    # shellcheck disable=SC1090
    . "$f"
    dbg "Sourced helper: $f"
    break
  fi
done

# ---------- Fallback: list_themes if helper didn't define it ----------
if ! command -v list_themes >/dev/null 2>&1; then
  list_themes() {
    # Emit selectable themes:
    #   family           (if <family>/style.css exists)
    #   family/variant   (if <family>/<variant>/style.css exists)
    local root="${WAYBAR_THEMES_DIR:-$HOME/.config/waybar/themes}"
    local d v base var
    shopt -s nullglob
    [[ -d "$root" ]] || return 0

    for d in "$root"/*; do
      [[ -d "$d" ]] || continue
      base="$(basename "$d")"
      [[ "$base" == "assets" ]] && continue

      # family root style
      if [[ -f "$d/style.css" ]]; then
        echo "$base"
      fi

      # variants
      for v in "$d"/*; do
        [[ -d "$v" ]] || continue
        var="$(basename "$v")"
        [[ -f "$v/style.css" ]] && echo "$base/$var"
      done
    done
  }
fi

# ---------- Fallback: switch_theme if helper didn't define it ----------
if ! command -v switch_theme >/dev/null 2>&1; then
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
    local c
    for c in "${cands[@]}"; do
      [[ -x "$c" ]] && { printf '%s\n' "$c"; return 0; }
    done
    command -v waybar-switch-theme >/dev/null 2>&1 && command -v waybar-switch-theme && return 0
    echo "ERROR: waybar-switch-theme not found (set WAYBAR_SWITCH)" >&2
    return 1
  }
  switch_theme() {
    local sel="${1:-}"
    [[ -n "$sel" ]] || { echo "switch_theme: missing selection" >&2; return 2; }
    local sw; sw="$(_waybar_switch_bin)" || return 3
    WAYBAR_THEME_DEBUG="${WAYBAR_THEME_DEBUG:-0}" "$sw" "$sel"
  }
fi

# Sanity for our (possibly helper‑provided) functions
command -v list_themes  >/dev/null 2>&1 || die "list_themes not found"
command -v switch_theme >/dev/null 2>&1 || die "switch_theme not found"

# ---------- Build entries ----------
mapfile -t ENTRIES < <(list_themes | sed '/\/$/d' | sort -u || true)
[[ ${#ENTRIES[@]} -gt 0 ]] || die "No selectable themes found (check ~/.config/waybar/themes)"

# ---------- Picker implementations ----------
run_picker_gui() {
  local prompt="${1:-Waybar theme}"
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    if command -v rofi >/dev/null 2>&1; then
      dbg "GUI: rofi"
      printf '%s\n' "${ENTRIES[@]}" | rofi -dmenu -p "$prompt" -i
      return $?
    fi
    if command -v wofi >/dev/null 2>&1; then
      dbg "GUI: wofi"
      printf '%s\n' "${ENTRIES[@]}" | wofi --dmenu --prompt="$prompt"
      return $?
    fi
  fi
  if [[ -n "${DISPLAY:-}" ]] && command -v rofi >/dev/null 2>&1; then
    dbg "GUI: rofi on X11"
    printf '%s\n' "${ENTRIES[@]}" | rofi -dmenu -p "$prompt" -i
    return $?
  fi
  return 127
}
run_picker_tui() {
  local prompt="${1:-Waybar theme}"
  if command -v fzf >/dev/null 2>&1; then
    dbg "TUI: fzf"
    printf '%s\n' "${ENTRIES[@]}" | fzf --prompt "$prompt> "
    return $?
  fi
  return 127
}

# ---------- Selection strategy ----------
PICKER="${WAYBAR_PICKER:-auto}"
SEL=""
case "$PICKER" in
  rofi)
    command -v rofi >/dev/null 2>&1 || die "rofi not found"
    SEL="$(printf '%s\n' "${ENTRIES[@]}" | rofi -dmenu -p 'Waybar theme' -i || true)"
    ;;
  wofi)
    command -v wofi >/dev/null 2>&1 || die "wofi not found"
    SEL="$(printf '%s\n' "${ENTRIES[@]}" | wofi --dmenu --prompt='Waybar theme' || true)"
    ;;
  fzf)
    command -v fzf  >/dev/null 2>&1 || die "fzf not found"
    SEL="$(printf '%s\n' "${ENTRIES[@]}" | fzf --prompt 'Waybar theme> ' || true)"
    ;;
  auto)
    if SEL="$(run_picker_gui 'Waybar theme' || true)"; [[ -z "$SEL" ]]; then
      SEL="$(run_picker_tui 'Waybar theme' || true)"
    fi
    ;;
  *)
    die "Unknown WAYBAR_PICKER: $PICKER (use rofi|wofi|fzf|auto)"
    ;;
esac

[[ -n "${SEL:-}" ]] || die "No selection made"

dbg "Selected: $SEL"
switch_theme "$SEL"

