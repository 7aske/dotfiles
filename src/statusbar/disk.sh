#!/usr/bin/env sh

# Status bar module for disk space
# $1 should be drive mountpoint
# $2 is optional icon, otherwise mountpoint will displayed

[ -z "$1" ] && exit

icon="$2"

SWITCH="$HOME/.cache/statusbar_$(basename $0)"

case $BLOCK_BUTTON in
	1) gnome-disks ;;
	2) [ -e "$SWITCH" ] && rm "$SWITCH" || touch "$SWITCH"; pkill -SIGRTMIN+9 i3blocks ;;
	3) baobab ;;
esac

color="#ffffff"
usage="$(df "$1" | awk 'NR==2 {print $4}')"

if [ -n "$usage" ]; then
	if [ $usage -lt 10485760 ]; then
		color="#D08770"
	elif [ $usage -lt 5242880 ]; then
		color="#BF616A"
	fi
fi

if [ -e "$SWITCH" ]; then
	printf "<span color='$color'>%s </span>\n" "$icon"
else
	printf "%s <span color='$color'>%s</span>\n" "$icon" "$(numfmt --to iec --from-unit=1024 --format "%f" $usage)"
fi
