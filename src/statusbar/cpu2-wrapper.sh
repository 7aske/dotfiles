#!/usr/bin/env bash

PREV_TOTAL=0
PREV_IDLE=0

SWITCH="$HOME/.cache/statusbar_cpu2" 

~/.local/bin/statusbar/cpu2 &
pid=$!

trap "trap - SIGTERM && kill -- -$$" SIGINT SIGTERM EXIT

while read button; do
    case $button in
        1) notify-send -i cpu "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
        2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
        3) i3-msg "exec --no-startup-id setsid -f st -c floating_popup -e htop" 2>/dev/null 1>/dev/null ;;
    esac
done
