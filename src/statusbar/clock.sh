#!/usr/bin/env sh

date +'%H:%M:%S'


case $BLOCK_BUTTON in
    1) 
	    pgrep -x dunst >/dev/null && notify-send -i date "Current date" "$(date +"%A %d %B %Y")"
    ;;
    3) 
        pgrep -x dunst >/dev/null && notify-send -i date "Calendar" "\n$(date +"%A %d %B %Y";echo ""; cal | sed "1d")"
    ;;
esac
