#!/usr/bin/env sh

[ -z "$CODE" ] && return 1
[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

case $BLOCK_BUTTON in
    1) notify-send -i git "Repositories" "$(cgs -mb | cut -c -80)" ;;
    3) notify-send -i git "Repositories" "$(cgs -v)" ;;
esac

repos="$(/usr/bin/cgs -b | wc -l)"

if [ "$repos" -le 1 ]; then
	color="${color7:-"#ffffff"}"
elif [ "$repos" -le 3 ]; then
    color="${color3:-"#fef44e"}"
elif [ "$repos" -le 5 ]; then
	color="${color5:-"#ff5252"}"
else
	color="${color1:-"#ff8144"}"
fi

if [ $repos -eq 0 ]; then
	exit 0
fi

echo "<span color='$color'>$repos</span>"


