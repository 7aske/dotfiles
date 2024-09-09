#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

SHORT_ICON=" "
FULL_ICON=" "
FULL_FORMAT="%a %d %b %H:%M:%S"
SHORT_FORMAT="%H:%M:%S"

case $BLOCK_BUTTON in
    1) notify-send -i date "Current date" "$(date +"%A %d %B %Y")" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
    3) wtoggle -T calcurse ;;
esac

if [ -e "$SWITCH" ]; then
    echo -n "$FULL_ICON"
    date +"$FULL_FORMAT"
else
    echo -n "$SHORT_ICON"
    date +"$SHORT_FORMAT"
fi
