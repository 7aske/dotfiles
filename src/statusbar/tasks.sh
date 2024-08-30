#!/usr/bin/env bash

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

show_tasklist() {
	i3-msg "exec --no-startup-id setsid -f $TERMINAL -c weather_floating -e taskwarrior-tui" 2>/dev/null 1>/dev/null
}

case $BLOCK_BUTTON in
	1) show_tasklist ;;
esac

tasks="$(task 2>/dev/null | tail -1 | awk '{print $1}')"

[ -z "$tasks" ] && exit 0

color="$color7"
if [ "$tasks" -ge 7 ]; then
	color="${color1:-"#BF616A"}"
elif [ "$tasks" -ge 5 ]; then
	color="${color3:-"#EBCB8B"}"
elif [ "$tasks" -ge 2 ]; then
    color="${color5:-"#B48EAD"}"
fi

echo " <span color='$color'>$tasks</span>"
