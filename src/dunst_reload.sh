#!/usr/bin/env sh

. "${HOME}/.cache/wal/colors.sh"

reload_dunst() {
    killall dunst && dunst \
        -frame_width 1 \
        -lb "${color0}" \
        -nb "${color0}" \
        -cb "${color0}" \
        -lfr "${color3}" \
        -nfr "${color4}" \
        -cfr "${color4}" \
        -lf "${color3}" \
        -cf "${color4}" \
        -nf "${color4}" \
        -bf "${color4}" \
        -separator_color "${color4}" \
        -conf ~/.config/dunst/dunstrc &
}

reload_dunst && notify-send "dunst" "dunst reloaded" 2>&1/dev/null
