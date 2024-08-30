#!/usr/bin/env bash

SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

case $BLOCK_BUTTON in
	1) notify-send -i device_mem "Memory hogs" "$(smem -Hkar | head)" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
	3) i3-msg "exec --no-startup-id setsid -f st -c floating_popup -e htop" 2>/dev/null 1>/dev/null ;;
esac

declare -a FREE
IFS=' '
for val in $(free --mega -h | awk '/^Mem:/ {print int($3 / $2 * 100) " " $3 "/" $2}'); do
	FREE+=($val)
done
	
# initial case where Mibs are comparted to Gibs
# and the resulting ratio is greater then 100
if [ "${FREE[0]}" -ge 100 ]; then
	color="${color7:-"#D8DEE9"}"
elif [ "${FREE[0]}" -ge 90 ]; then
	color="${color1:-"#BF616A"}"
elif [ "${FREE[0]}" -ge 75 ]; then
	color="${color3:-"#D08770"}"
elif [ "${FREE[0]}" -ge 50 ]; then
    color="${color2:-"#EBCB8B"}"
else
	color="${color7:-"#D8DEE9"}"
fi

ICON=""

if [ -e "$SWITCH" ]; then
	printf "<span color='%s'>%s </span>\n" "$color" "$ICON"
else
	printf "$ICON <span color='%s'>%s</span>\n" "$color" "${FREE[1]}"
fi

