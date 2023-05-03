#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

[ -z "$CODE" ] && return 1
[ -f  "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
[ -f  "$HOME/.cache/wal/colors.sh" ] && . "$HOME/.cache/wal/colors.sh"

case $BLOCK_BUTTON in
    1) 
		if [ $(dunstctl is-paused) = true ]; then
			cgs | awk -F ' ' '{for(i=1;i<=NF;i++){print $i}}' | \
				zenity --list \
				--column Lang \
				--column Name \
				--column Branch \
				--class=STATUSBAR_POPUP \
				--title="rgs"
				--text="Dirty repositories:"
		else 
			notify-send -i git "Repositories" "$(cgs -mb)"
		fi ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) notify-send -i git "Repositories" "$(cgs -F)" ;;
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
  
ICON='󰊢'

if [ $repos -eq 0 ]; then
	exit 0
fi

if [ -e "$SWITCH" ]; then
	echo "<span size='medium' color='$color'>$ICON </span>"
else
	echo "<span size='medium'>$ICON</span> <span color='$color'>$repos</span>"
fi



