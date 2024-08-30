#!/usr/bin/env sh

[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"


exec /bin/dmenu \
	-nb "${color0}" \
	-nf "${color6}" \
	-sb "${color10}" \
	-sf "${color8}" \
	"$@"

