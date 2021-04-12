#!/usr/bin/env sh

# Status bar module for disk space
# $1 should be drive mountpoint
# $2 is optional icon, otherwise mountpoint will displayed

[ -z "$1" ] && exit

icon="$2"

case $BLOCK_BUTTON in
	1) pgrep -x dunst >/dev/null && \
		notify-send -i drive-harddisk " Disk space" "$(df -h --output=source,avail,size,target | grep -e "^/" -e "Filesystem" | grep -ve "boot" -e "efi")" ;;
	2) gnome-disks ;;
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


printf "%s <span color='$color'>%s</span>\n" "$icon" "$(numfmt --to iec --from-unit=1024 --format "%f" $usage)"
