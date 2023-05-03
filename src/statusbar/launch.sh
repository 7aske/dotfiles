#!/usr/bin/env bash

# killswitch
SWITCH="$HOME/.cache/statusbar_$(basename $0)" 
case $BLOCK_BUTTON in
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
esac

if [ -e "$SWITCH" ]; then
	exit 0;
fi

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh" 

web_url="https://go4liftoff.com/launches"
api_url="https://fdo.rocketlaunch.live/json/launches/next/5"

show_summary() {
	data="$(curl "$api_url" | jq -jr '.result[] | .date_str, "|", .name, "|", (.win_open | strptime("%Y-%m-%dT%H:%MZ") |  strflocaltime("%H:%M"))?, "|", (.t0 | strptime("%Y-%m-%dT%H:%MZ") |  strflocaltime("%H:%M"))?, "\n"')"
	notify-send -a "launches" -i rocket "Upcoming launches" "$today\n\n$(echo -e "Date|Name|Win Open|T0|\n$data" | column -t -s'|')"
}

today="$(date +"%b %d")"
case $BLOCK_BUTTON in
	1) show_summary ;;
	3) xdg-open "$web_url" 2>&1 >/dev/null ;;
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



echo "󰑣 $launches<span color='$color'>$extra</span>"
