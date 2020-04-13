#!/usr/bin/env sh

. "${HOME}/.cache/wal/colors.sh"

exec /bin/dmenu -nb "${color0}" -nf "${color7}" -sb "${color2}" -sf "${color7}" "$@"
