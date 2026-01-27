#!/usr/bin/env sh

SWITCH="$HOME/.cache/statusbar_$(basename "$0")" 

case $BLOCK_BUTTON in
	1) notify-send -i cpu "CPU hogs" "$(ps axch -o cmd:15,%cpu --sort=-%cpu | head)" ;;
	2) if [ -e "$SWITCH" ]; then rm "$SWITCH"; else touch "$SWITCH"; fi ;;
	3) wtoggle2 -T htop 2>/dev/null 1>/dev/null ;;
esac

cpu_usage="$(mpstat 1 1 | grep 'Average:' | awk '{printf "%d", ((100 - $12))}')"

if [ "$cpu_usage" -ge 75 ]; then
    icon="󰡴"
	color="${color1:-"#BF616A"}"
elif [ "$cpu_usage" -ge 50 ]; then
    icon="󰊚"
	color="${color3:-"#D08770"}"
elif [ "$cpu_usage" -ge 25 ]; then
    icon="󰡵"
    color="${color2:-"#EBCB8B"}"
else
    icon="󰡳"
	color="${color7:-"#D8DEE9"}"
fi

if [ -e "$SWITCH" ]; then
	printf "<span color='%s' size='large'>%s </span>\n" "$color" "$icon"
else
	printf "<span size='large'>$icon</span> <span color='%s'>%3d%%</span>\n" "$color" "$cpu_usage"
fi
