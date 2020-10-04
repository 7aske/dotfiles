#!/usr/bin/env sh

if [ -f  "$HOME/.cache/wal/colors.sh" ]; then 
	. "$HOME/.cache/wal/colors.sh"
	exec /bin/dmenu -nb "${color0}" -nf "${color7}" -sb "${color2}" -sf "${color7}" "$@"
else
	exec /bin/dmenu "$@"
fi

