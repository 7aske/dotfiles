#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
esac

mpstat 1 1 | grep 'Average:' | awk '{printf "%d%\n", $3}'
