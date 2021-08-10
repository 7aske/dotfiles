#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
esac

sensors | awk '/Package id 0:/{print substr($4, 2)} /Tdie/{print substr($2, 2)}'
