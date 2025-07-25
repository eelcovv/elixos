#!/usr/bin/env bash
#  _____                 _       __        __          _
# |_   _|__   __ _  __ _| | ___  \ \      / /_ _ _   _| |__   __ _ _ __
#   | |/ _ \ / _` |/ _` | |/ _ \  \ \ /\ / / _` | | | | '_ \ / _` | '__|
#   | | (_) | (_| | (_| | |  __/   \ V  V / (_| | |_| | |_) | (_| | |
#   |_|\___/ \__, |\__, |_|\___|    \_/\_/ \__,_|\__, |_.__/ \__,_|_|
#            |___/ |___/                         |___/
#

if [ -f $HOME/.config/hypr/settings/waybar-disabled ]; then
    rm $HOME/.config/hypr/settings/waybar-disabled
else
    touch $HOME/.config/hypr/settings/waybar-disabled
fi
$HOME/.config/waybar/launch.sh &
