#!/usr/bin/env bash

case $BLOCK_BUTTON in
	1) notify-send -i device_mem "Memory hogs" "$(smem -Hkar | head)" ;;
esac

declare -a FREE
IFS=' '
for val in $(free --mega -h | awk '/^Mem:/ {print int($3 / $2 * 100) " " $3 "/" $2}'); do
	FREE+=($val)
done
	
if [ "${FREE[0]}" -ge 90 ]; then
	color="${color1:-"#BF616A"}"
elif [ "${FREE[0]}" -ge 75 ]; then
	color="${color3:-"#D08770"}"
elif [ "${FREE[0]}" -ge 50 ]; then
    color="${color2:-"#EBCB8B"}"
else
	color="${color7:-"#D8DEE9"}"
fi

printf "<span color='%s'>%s</span>\n" "$color" "${FREE[1]}"
