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
    # Args: <theme/variant>; populates ~/.config/waybar/current/* with best-available targets.
    local theme="$1"

    local cfg="$HOME/.config/waybar"
    local base="$cfg/themes"
    local cur="$cfg/current"
    local theme_root="${theme%%/*}"    # "ml4w" from "ml4w/light"
    local var_dir="$base/$theme"
    local theme_dir="$base/$theme_root"
    local def_dir="$base/default"

    local mod_global="$cfg/modules.jsonc"
    local col_global="$cfg/colors.css"

    ensure_theme_variant "$base" "$theme" || return 1
    mkdir -p "$cur"

    # Resolve with fallbacks: variant -> theme -> default -> global
    local cfg_src mod_src css_src col_src

    if [[ -e "$var_dir/config.jsonc" ]]; then
        cfg_src="$var_dir/config.jsonc"
    elif [[ -e "$theme_dir/config.jsonc" ]]; then
        cfg_src="$theme_dir/config.jsonc"
    else
        cfg_src="$def_dir/config.jsonc"
    fi

    if [[ -e "$var_dir/modules.jsonc" ]]; then
        mod_src="$var_dir/modules.jsonc"
    elif [[ -e "$theme_dir/modules.jsonc" ]]; then
        mod_src="$theme_dir/modules.jsonc"
    elif [[ -e "$def_dir/modules.jsonc" ]]; then
        mod_src="$def_dir/modules.jsonc"
    else
        mod_src="$mod_global"
    fi

    if [[ -e "$var_dir/style.css" ]]; then
        css_src="$var_dir/style.css"
    elif [[ -e "$var_dir/style-custom.css" ]]; then
        css_src="$var_dir/style-custom.css"
    elif [[ -e "$def_dir/style.css" ]]; then
        css_src="$def_dir/style.css"
    else
        css_src="$def_dir/style-custom.css"
    fi

    if [[ -e "$var_dir/colors.css" ]]; then
        col_src="$var_dir/colors.css"
    elif [[ -e "$theme_dir/colors.css" ]]; then
        col_src="$theme_dir/colors.css"
    else
        col_src="$col_global"
    fi

    [[ -n "$cfg_src" && -e "$cfg_src" ]] && ln -sfn "$cfg_src" "$cur/config.jsonc"
    [[ -n "$mod_src" && -e "$mod_src" ]] && ln -sfn "$mod_src" "$cur/modules.jsonc"

    if [[ -n "$col_src" && -e "$col_src" ]]; then
        ln -sfn "$col_src" "$cur/colors.css"
    else
        : > "$cur/colors.css"
    fi

    # Always build a safe, preprocessed CSS:
    #   1) copy the chosen CSS,
    #   2) replace literal ~/colors.css -> colors.css,
    #   3) always prepend an import for colors.css
    if [[ -n "$css_src" && -e "$css_src" ]]; then
        cp "$css_src" "$cur/style.resolved.css"
        sed -i -e 's#~/colors\.css#colors.css#g' "$cur/style.resolved.css"
        printf '@import url("colors.css");\n' | cat - "$cur/style.resolved.css" > "$cur/.tmp.css" && mv "$cur/.tmp.css" "$cur/style.resolved.css"
    else
        printf '@import url("colors.css");\n' > "$cur/style.resolved.css"
    fi

    systemctl --user restart waybar.service
    notify "Waybar theme" "Applied: $theme"
}
