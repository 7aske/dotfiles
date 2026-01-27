#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename "$0")" 

case $BLOCK_BUTTON in
    1) notify-send -i date "Current date" "$(date +"%A %d %B %Y")" ;;
	2) if [ -e "$SWITCH" ]; then rm "$SWITCH"; else touch "$SWITCH"; fi ;;
    3) wtoggle2 -T calcurse ;;
esac

if [ -e "$SWITCH" ]; then
    icon=" "
    format="%H:%M:%S"
else
    icon=" "
    format="%a %d %b %H:%M:%S"
fi

echo "$icon$(date +"$format")"
