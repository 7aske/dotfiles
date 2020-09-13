#!/usr/bin/env sh
case $BLOCK_BUTTON in
	1) notify-send "Weather" "$(curl wttr.in/ | perl -pe 's/\e\[[0-9;]*m(?:\e\[K)?//g' | head -7)" ;;
esac

echo "$(curl wttr.in/?format=%t)"
