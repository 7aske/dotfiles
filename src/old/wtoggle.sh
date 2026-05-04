#!/usr/bin/env bash

usage() {
    echo "usage: wtoggle <command>"
    exit 2
}

class=""

while getopts "c:" arg; do
	case $arg in
		c) class="$OPTARG" ;;
	esac
done

shift $((OPTIND - 1))

[ -z "$1" ] && usage

[ -z "$class" ] && class="$1"

program="$(basename $1)"
if [ -z "$class" ]; then
	processes="$(pgrep -cf "$program" -O 1)"
else
	processes="$(pgrep -cf "$class|$program" -O 1)"
fi

if [ "$processes" -gt 0 ]; then
	active="$(xdotool getactivewindow)"
	visible_windows="$(xdotool search --onlyvisible --class $class)"
	focused=0
	for win in $visible_windows; do
		if [ "$win" -eq "$active" ]; then
			focused=1
			break
		fi
	done

	visible="$(echo $visible_windows | tr ' ' '\n' | xargs -I% xprop -id % | grep -c "window state: Normal")"
	echo $visible_windows
	echo $visible $focused
	if [ "$visible" -gt 0 ] && [ $focused -eq 1 ]; then
		for win in $(xdotool search --onlyvisible --class $class); do 
			if grep -q "window state: Normal" <(xprop -id $win); then
				xdotool windowunmap $win
			fi
		done
	else
		for win in $(xdotool search --class $class); do
			if grep -iq "window state: withdrawn" <(xprop -id $win) \
				|| ( [ $focused -eq 0 ] && ! grep -q "CLIENT_LEADER" <(xprop -id $win)  ); then
				xdotool windowmap $win
				xdotool set_desktop_for_window $win $(xdotool get_desktop)
				xdotool windowactivate $win
			fi
		done
	fi
else
    (setsid $program 2>/dev/null 1>/dev/null) &
fi
