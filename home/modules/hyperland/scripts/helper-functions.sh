#!/usr/bin/env bash
# Common helpers for Waybar theme switching.
# NOTE: do not set shell options here; callers should use: set -euo pipefail

notify() {
    # Notify terminal (stdout), optionally journal and desktop.
    local title="$1"; shift
    local body="${*:-}"
    printf '%s: %s\n' "$title" "$body"
    if command -v logger >/dev/null 2>&1; then
        logger -t waybar-theme -- "$title: $body"
    fi
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$title" "$body" || true
    fi
}

ensure_theme_variant() {
    # Args: <base_dir> <theme/variant>
    local base="$1"
    local theme="$2"
    if [[ ! -d "$base/$theme" ]]; then
        echo "Unknown theme variant: $theme"
        return 1
    fi
    if [[ ! -f "$base/$theme/style.css" && ! -f "$base/$theme/style-custom.css" ]]; then
        echo "Variant '$theme' has no style.css"
        return 1
    fi
}

list_theme_variants() {
    # Arg (optional): <base_dir>; default = ~/.config/waybar/themes
    local base="${1:-$HOME/.config/waybar/themes}"
    find "$base" -mindepth 1 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -printf '%P\n' 2>/dev/null \
        | sed -E 's#/style(-custom)?\.css$##' \
        | sort -u
}

switch_theme() {
    # Args: <theme/variant>; uses ~/.config/waybar/{themes,current}
    local theme="$1"
    local base="$HOME/.config/waybar/themes"
    local cur="$HOME/.config/waybar/current"
    ensure_theme_variant "$base" "$theme"
    ln -sfn "$base/$theme" "$cur"
    systemctl --user restart waybar.service
    notify "Waybar theme" "Applied: $theme"
}
