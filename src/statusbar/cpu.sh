#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send -i cpu "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
	3) i3-msg "exec --no-startup-id setsid -f st -c floating_popup -e htop" 2>&1>/dev/null ;;
esac

mpstat 1 1 | grep 'Average:' | awk '{printf "%d%\n", $3}'
