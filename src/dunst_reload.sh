#!/usr/bin/env sh

killall dunst
if [ -f  "${HOME}/.cache/wal/colors.sh" ]; then
    . "${HOME}/.cache/wal/colors.sh"
    dunst \
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
else
    dunst \
        -frame_width 1 \
        -conf ~/.config/dunst/dunstrc &
fi

