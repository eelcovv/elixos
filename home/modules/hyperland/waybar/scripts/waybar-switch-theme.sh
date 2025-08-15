#!/usr/bin/env bash
set -euo pipefail

# Script to switch the Waybar theme without spawning new Waybar processes.
# Usage: waybar-switch-theme <theme-subdir> (e.g., ml4w/dark)

THEME="${1:-}"
THEMES_DIR="${HOME}/.config/waybar/themes"
CUR="${HOME}/.config/waybar/current"
CFG="${HOME}/.config/waybar"

if [[ -z "${THEME}" ]]; then
  echo "Usage: waybar-switch-theme <theme-subdir> (e.g., ml4w/dark)" >&2
  exit 2
fi

THEME_DIR="${THEMES_DIR}/${THEME}"
if [[ ! -d "${THEME_DIR}" ]]; then
  echo "Theme not found: ${THEME_DIR}" >&2
  exit 3
fi

# Skip folders like 'assets'
case "${THEME}" in
  assets*|*/assets|*assets/*)
    echo "Not a valid theme folder: ${THEME}" >&2
    exit 4
    ;;
esac

mkdir -p "${CUR}"

# Link config.jsonc (prefer theme-specific version, fallback to default)
if [[ -f "${THEME_DIR}/config.jsonc" ]]; then
  ln -sfn "${THEME_DIR}/config.jsonc" "${CUR}/config.jsonc"
else
  [[ -f "${CUR}/config.jsonc" ]] || printf '{ "modules-left": [], "modules-center": [], "modules-right": [] }\n' > "${CUR}/config.jsonc"
fi

# Link modules.jsonc (prefer theme-specific version, fallback to global)
if [[ -f "${THEME_DIR}/modules.jsonc" ]]; then
  ln -sfn "${THEME_DIR}/modules.jsonc" "${CUR}/modules.jsonc"
else
  ln -sfn "${CFG}/modules.jsonc" "${CUR}/modules.jsonc"
fi

# Link colors.css (prefer theme-specific version, fallback to global)
if [[ -f "${THEME_DIR}/colors.css" ]]; then
  ln -sfn "${THEME_DIR}/colors.css" "${CUR}/colors.css"
elif [[ -f "${CFG}/colors.css" ]]; then
  ln -sfn "${CFG}/colors.css" "${CUR}/colors.css"
else
  : > "${CUR}/colors.css"
fi

# Build style.resolved.css (imports colors.css first, then theme CSS)
CSS_SRC=""
if   [[ -f "${THEME_DIR}/style.css" ]]; then CSS_SRC="${THEME_DIR}/style.css"
elif [[ -f "${THEME_DIR}/style-custom.css" ]]; then CSS_SRC="${THEME_DIR}/style-custom.css"
fi

if [[ -n "${CSS_SRC}" ]]; then
  cp -f "${CSS_SRC}" "${CUR}/style.resolved.css"
  # Remove any imports of style.css or colors.css from the original theme
  sed -i -E '/@import.*\.\.\/style\.css/d;/@import.*colors\.css/d' "${CUR}/style.resolved.css"
  # Prepend our colors.css import so theme variables are always available
  printf '@import url("colors.css");\n' | cat - "${CUR}/style.resolved.css" > "${CUR}/.tmp.css"
  mv -f "${CUR}/.tmp.css" "${CUR}/style.resolved.css"
else
  printf '@import url("colors.css");\n' > "${CUR}/style.resolved.css"
fi

# Reload the running Waybar instance (without spawning a new one)
pkill -SIGUSR2 -x waybar || true

