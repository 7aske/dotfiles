#!/usr/bin/env bash

web_url="https://go4liftoff.com/launches"
api_url="https://fdo.rocketlaunch.live/json/launches/next/5"

case $BLOCK_BUTTON in
	1) notify-send -i rocket "Upcoming launches" "$(date +"%b %d")\n\n$(curl "$api_url" | jq -jr '.result[] | .date_str, "|", .name, "|", select(.t0!=null), "\n"' | column -t -s'|')" ;;
	3) xdg-open "$web_url" ;;
esac

launches=$(curl "$api_url" | jq ".count")

if [ "$launches" -eq 0 ] || [ "$launches" = "null" ]; then
	exit 0
fi

echo "異 $launches"
