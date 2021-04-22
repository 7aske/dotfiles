#!/usr/bin/env bash

# sets cpu rgb color based on current cpu usage(green -> red)

while true; do
	usage="$(mpstat 1 1 | grep 'Average:' | awk '{printf "%d\n", ((100.0 - $12))}')"
	abs_usage=$(($usage * 255 / 100))
	green=$((255 - abs_usage))
	color="$(printf "%02x" $abs_usage)$(printf "%02x" $green)00"
	echo "$usage -> $color"
	openrgb -d 0 -c "$color" -c "000000" --noautoconnect  2>/dev/null 1>/dev/null
done
