#!/usr/bin/env bash

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

web_url="https://go4liftoff.com/launches"
api_url="https://fdo.rocketlaunch.live/json/launches/next/5"

today="$(date +"%b %d")"
case $BLOCK_BUTTON in
	1) notify-send -i rocket "Upcoming launches" "$today\n\n$(curl "$api_url" | jq -jr '.result[] | .date_str, "|", .name, "|", select(.t0!=null), "\n"' | column -t -s'|')" ;;
	3) xdg-open "$web_url" ;;
esac

launch_data="$(curl -s "$api_url")"
launches=$(echo "$launch_data" | jq ".count")
launches_today=0

for index in $(seq 0 $((launches-1))); do
	while IFS='|' read launch_date t0 win_open; do
		if [ "$launch_date" != "$today" ]; then
			break
		fi
		timestamp="$(date -d "$launch_date 12PM" +"%s")"
		if [ "$t0" != "null" ]; then
			timestamp="$(date -d "$t0" +"%s")"
		elif [ "$win_open" != null ]; then 
			timestamp="$(date -d "$win_open" +"%s")"
		fi

		if [ $timestamp -gt $(date +"%s") ]; then
			((launches_today++))
		fi
	done <<<$(echo "$launch_data" | jq -jr ".result[$index] | .date_str, \"|\", .t0, \"|\", .win_open, \"|\", \"\n\"")
done

if [ "$launches" -eq 0 ] || [ "$launches" = "null" ]; then
	exit 0
fi

color="$color7"
extra=""
if [ "$launches_today" -gt 0 ]; then 
	extra=" ($launches_today)"
	color="$color3"
fi



echo "異 $launches<span color='$color'>$extra</span>"
