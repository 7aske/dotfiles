#!/usr/bin/env bash

# killswitch
SWITCH="$HOME/.cache/statusbar_$(basename $0)" 

show_weather() {
	#i3-msg "workspace weather"
	curl -s http://wttr.in/"$WEATHER" > /tmp/weather 2>&1
	i3-msg "exec --no-startup-id setsid -f st -c weather_floating -e less -Srf /tmp/weather" 2>/dev/null 1>/dev/null
}

case $BLOCK_BUTTON in
	1) notify-send -i none "Weather" "$(curl wttr.in/"$WEATHER" | perl -pe 's/\e\[[0-9;]*m(?:\e\[K)?//g' | head -7)" ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH" ;;
	3) show_weather ;;
esac

FORMAT="%c%t"
if [ -e "$SWITCH" ]; then
	FORMAT="%c"
fi

weather="$(curl wttr.in/"$WEATHER"?format="$FORMAT")"
if ! [[ "$weather" =~ "Unknown location" ]]; then
	echo $weather | awk '{print $1 "<span rise=\"-2pt\">" $2 "</span>"}'
else
	echo " "
fi
