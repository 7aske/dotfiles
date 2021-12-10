#!/usr/bin/env bash

TIMEOUT="${TIMEOUT:-5}"
[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"

ICON=""

trap 'exit 130' SIGINT

while true; do
	color="${color7:-'#D8DEE9'}"
	read -t $TIMEOUT button
	case $button in
		1) if [ -e "/tmp/statusbar-power" ]; then
			rm "/tmp/statusbar-power" 
		else
			touch "/tmp/statusbar-power" 
		fi 
		notify-send -a 'Power' -i preferences-system-power 'Power' 'Toggled presentation mode' ;;
	esac

	inhibit=0

	if pgrep -xf stremio; then
		color="${color2:-'#A3BE8C'}"
		inhibit=1
	fi

	if [ "$(playerctl status)" = 'Playing' ]; then
		color="${color2:-'#A3BE8C'}"
		inhibit=1
	fi

	if systemd-inhibit --list | grep -q 'xfce4-power-manager.*xfce4-screensav.*idle.*Inhibit requested'; then
		color="${color3:-'#EBCB8B'}"
		inhibit=1
	fi

	if [ -e /tmp/statusbar-power ]; then
		color="${color3:-'#EBCB8B'}"
		inhibit=1
	fi


	echo "<span color='$color'>$ICON</span>"

	if [ "$inhibit" -eq 1 ];then
		# we use read timeout as the loop delay
		systemd-inhibit --who='statusbar/power' --why='User or player requested' --what=sleep:idle --mode=block sleep $TIMEOUT &
	fi
done
