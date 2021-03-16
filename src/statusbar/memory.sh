#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send -i device_mem "Memory hogs" "$(ps axch -o cmd:15,%mem --sort=-%mem | head)" ;;
esac

free --mega -h | awk '/^Mem:/ {print $3 "/" $2}'
#free | awk '/^Mem:/ {printf "%d%\n", (($3 / $2 * 100 ))}'
