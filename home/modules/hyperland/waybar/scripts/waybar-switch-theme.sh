#!/usr/bin/env bash
set -euo pipefail

# Switch Waybar theme without spawning a new instance.
# Accepts themes like "default" or nested ones like "ml4w/dark".

THEME="${1:-}"
THEMES_DIR="${HOME}/.config/waybar/themes"
CUR="${HOME}/.config/waybar/current"
CFG="${HOME}/.config/waybar"

if [[ -z "${THEME}" ]]; then
  echo "Usage: waybar-switch-theme <theme-subdir> (e.g., default or ml4w/dark)" >&2
  exit 2
fi

THEME_DIR="${THEMES_DIR}/${THEME}"
if [[ ! -d "${THEME_DIR}" ]]; then
  echo "Theme not found: ${THEME_DIR}" >&2
  exit 3
fi

# Disallow non-theme utility folders
case "${THEME}" in
  assets*|*/assets|*assets/*)
    echo "Not a valid theme folder: ${THEME}" >&2
    exit 4
    ;;
esac

mkdir -p "${CUR}"

# Helper: choose a file from THEME_DIR or, if missing, from the parent folder (one level up)
pick_with_parent_fallback() {
  local rel="$1"
  local child="${THEME_DIR}/${rel}"
  if [[ -f "${child}" ]]; then
    printf '%s\n' "${child}"
    return 0
  fi
  # Try parent (e.g., ml4w/config.jsonc when theme is ml4w/dark)
  if [[ "${THEME_DIR}" == */* ]]; then
    local parent="${THEME_DIR%/*}/${rel}"
    if [[ -f "${parent}" ]]; then
      printf '%s\n' "${parent}"
      return 0
    fi
  fi
  return 1
}

# Link config.jsonc (prefer THEME, then parent; otherwise keep existing or minimal)
if SRC="$(pick_with_parent_fallback 'config.jsonc')"; then
  ln -sfn "${SRC}" "${CUR}/config.jsonc"
else
  [[ -f "${CUR}/config.jsonc" ]] || printf '{ "modules-left": [], "modules-center": [], "modules-right": [] }\n' > "${CUR}/config.jsonc"
fi

# Link modules.jsonc (prefer THEME, then parent; otherwise global)
if SRC="$(pick_with_parent_fallback 'modules.jsonc')"; then
  ln -sfn "${SRC}" "${CUR}/modules.jsonc"
else
  ln -sfn "${CFG}/modules.jsonc" "${CUR}/modules.jsonc"
fi

# Link colors.css (prefer THEME, then parent; otherwise global or empty)
if SRC="$(pick_with_parent_fallback 'colors.css')"; then
  ln -sfn "${SRC}" "${CUR}/colors.css"
elif [[ -f "${CFG}/colors.css" ]]; then
  ln -sfn "${CFG}/colors.css" "${CUR}/colors.css"
else
  : > "${CUR}/colors.css"
fi

# Build style.resolved.css (prefer THEME style.css, then parent, then empty with colors import)
CSS_SRC=""
if SRC="$(pick_with_parent_fallback 'style.css')"; then
  CSS_SRC="${SRC}"
elif SRC="$(pick_with_parent_fallback 'style-custom.css')"; then
  CSS_SRC="${SRC}"
fi

if [[ -n "${CSS_SRC}" ]]; then
  cp -f "${CSS_SRC}" "${CUR}/style.resolved.css"
  sed -i -E '/@import.*\.\.\/style\.css/d; /@import.*colors\.css/d' "${CUR}/style.resolved.css"
  printf '@import url("colors.css");\n' | cat - "${CUR}/style.resolved.css" > "${CUR}/.tmp.css"
  mv -f "${CUR}/.tmp.css" "${CUR}/style.resolved.css"
else
  printf '@import url("colors.css");\n' > "${CUR}/style.resolved.css"
fi

# Reload the running Waybar instance
pkill -SIGUSR2 -x waybar || true

