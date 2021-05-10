#!/usr/bin/env sh

case $BLOCK_BUTTON in
	1) notify-send -i cpu "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
	3) i3-msg "exec --no-startup-id setsid -f st -c floating_popup -e htop" 2>/dev/null 1>/dev/null ;;
esac

cpu_usage="$(mpstat 1 1 | grep 'Average:' | awk '{printf "%d", ((100 - $12))}')"


if [ "$cpu_usage" -ge 90 ]; then
	color="${color1:-"#BF616A"}"
elif [ "$cpu_usage" -ge 75 ]; then
	color="${color3:-"#D08770"}"
elif [ "$cpu_usage" -ge 50 ]; then
    color="${color2:-"#EBCB8B"}"
else
	color="${color7:-"#D8DEE9"}"
fi

printf "<span color='%s'>%d%%</span>\n" "$color" "$cpu_usage"
