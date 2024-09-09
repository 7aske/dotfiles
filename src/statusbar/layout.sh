#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send -i keyboard "Keyboard Layout" "Toggle" && kblang -l us,rs-latin,rs -t ;;
	3) notify-send -i keyboard "Keyboard Layout" "$(setxkbmap -query)" ;;
esac


setxkbmap -query | grep layout | awk '{print $2}'
