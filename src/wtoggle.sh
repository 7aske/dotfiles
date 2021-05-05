#!/usr/bin/env bash

usage() {
    echo "usage: wtoggle <command>"
    exit 2
}

[ -z "$1" ] && usage

program="$(basename $1)"
processes="$(pgrep -x "$program")"

if [ -n "$processes" ]; then
	visible="$(xdotool search --onlyvisible --name $program | xargs -I% xprop -id % | grep -c "window state: Normal")"
	if [ "$visible" -gt 0 ]; then
		for win in $(xdotool search --onlyvisible --name $program); do 
			if grep -q "window state: Normal" <(xprop -id $win); then
				xdotool windowunmap $win
			fi
		done
	else
		for win in $(xdotool search --name $program); do
			if grep -q "window state: Withdrawn" <(xprop -id $win); then
				xdotool windowmap $win
			fi
		done
	fi
else
    (setsid $program 2>/dev/null 1>/dev/null) &
fi
