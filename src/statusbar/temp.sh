#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
esac

sensors | grep 'Tdie' | awk '{print $2}'
