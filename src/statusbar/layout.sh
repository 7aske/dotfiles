#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send "Keyboard Layout" "$(setxkbmap -query)" ;;
esac


setxkbmap -query | grep layout | awk '{print $2}'
