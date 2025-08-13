#!/usr/bin/env bash
# Common helpers for Waybar theme switching.
# NOTE: callers should use: set -euo pipefail

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

list_theme_variants() {
    # Arg (optional): <base_dir>; default = ~/.config/waybar/themes
    local base="${1:-$HOME/.config/waybar/themes}"
    find "$base" -mindepth 1 -maxdepth 2 -type f \( -name 'style.css' -o -name 'style-custom.css' \) -printf '%P\n' 2>/dev/null \
        | sed -E 's#/style(-custom)?\.css$##' \
        | sort -u
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

_pick_first() {
    # Echo the first existing path among args.
    local p
    for p in "$@"; do
        [[ -e "$p" ]] && { printf '%s\n' "$p"; return 0; }
    done
    return 1
}

switch_theme() {
    # Args: <theme/variant>; populates ~/.config/waybar/current/* with best-available links.
    local theme="$1"

    local cfg="$HOME/.config/waybar"
    local base="$cfg/themes"
    local cur="$cfg/current"
    local theme_root="${theme%%/*}"          # "ml4w" from "ml4w/light"
    local var_dir="$base/$theme"             # variant dir (may miss config/modules/colors)
    local theme_dir="$base/$theme_root"      # theme-level dir
    local def_dir="$base/default"            # default variant dir

    # Global fallbacks (installed by Nix)
    local mod_global="$cfg/modules.jsonc"
    local col_global="$cfg/colors.css"

    ensure_theme_variant "$base" "$theme" || return 1

    mkdir -p "$cur"

    # Resolve files with fallbacks: variant -> theme -> default -> global (where applicable)
    local cfg_src mod_src css_src col_src

    cfg_src=$(_pick_first \
        "$var_dir/config.jsonc" \
        "$theme_dir/config.jsonc" \
        "$def_dir/config.jsonc" \
    )
    mod_src=$(_pick_first \
        "$var_dir/modules.jsonc" \
        "$theme_dir/modules.jsonc" \
        "$def_dir/modules.jsonc" \
        "$mod_global" \
    )
    css_src=$(_pick_first \
        "$var_dir/style.css" \
        "$var_dir/style-custom.css" \
        "$def_dir/style.css" \
        "$def_dir/style-custom.css" \
    )
    col_src=$(_pick_first \
        "$var_dir/colors.css" \
        "$theme_dir/colors.css" \
        "$col_global" \
    )

    # Update links atomically
    ln -sfn "$cfg_src" "$cur/config.jsonc"
    ln -sfn "$mod_src" "$cur/modules.jsonc"
    ln -sfn "$css_src" "$cur/style.css"
    # colors is optional; if absent entirely, create an empty file to avoid import errors
    if [[ -n "${col_src:-}" ]]; then
        ln -sfn "$col_src" "$cur/colors.css"
    else
        : > "$cur/colors.css"
    fi

    systemctl --user restart waybar.service
    notify "Waybar theme" "Applied: $theme"
}

