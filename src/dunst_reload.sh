#!/usr/bin/env sh

killall dunst

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

dunst \
    -frame_width 1 \
    -nb  "${color0}" \
    -nfr "${color4}" \
    -nf  "${color6}" \
    -lb  "${color0}" \
    -lfr "${color4}" \
    -lf  "${color4}" \
    -cb  "${color1}" \
    -cfr "${color4}" \
    -cf  "${color8}" \
    -bf  "${color4}" \
    -separator_color "${color4}" \
    -conf ~/.config/dunst/dunstrc &

notify-send -u normal   "dunst" "dunst reloaded"
notify-send -u critical "dunst" "dunst reloaded"
notify-send -u low      "dunst" "dunst reloaded"
