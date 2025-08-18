#!/usr/bin/env bash
set -euo pipefail
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/waybar"
CUR="$CFG/current"
DEF="$CFG/themes/default"

mkdir -p "$CUR"
[[ -f "$DEF/style.css" ]]       && install -Dm0644 "$DEF/style.css"       "$CUR/style.resolved.css"
[[ -f "$DEF/colors.css" ]]      && install -Dm0644 "$DEF/colors.css"      "$CUR/colors.css"
[[ -f "$DEF/modules.jsonc" ]]   && install -Dm0644 "$DEF/modules.jsonc"   "$CUR/modules.jsonc" || printf '{}\n' > "$CUR/modules.jsonc"
[[ -f "$DEF/config.jsonc" ]]    && install -Dm0644 "$DEF/config.jsonc"    "$CUR/config.jsonc"  || printf '{ "modules-center": ["clock"], "clock": { "format":"{:%H:%M}" } }\n' > "$CUR/config.jsonc"

ln -sfn "$CUR/config.jsonc"       "$CFG/config"
ln -sfn "$CUR/config.jsonc"       "$CFG/config.jsonc"
ln -sfn "$CUR/modules.jsonc"      "$CFG/modules.jsonc"
ln -sfn "$CUR/colors.css"         "$CFG/colors.css"
ln -sfn "$CUR/style.resolved.css" "$CFG/style.css"

echo "[seed] default seeded."

