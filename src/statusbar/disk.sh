#!/usr/bin/env sh

# Status bar module for disk space
# $1 should be drive mountpoint
# $2 is optional icon, otherwise mountpoint will displayed

[ -z "$1" ] && exit

icon="$2"
[ -z "$2" ] && icon="$1"

case $BLOCK_BUTTON in
	1) pgrep -x dunst >/dev/null && \
		notify-send -i drive-harddisk " Disk space" "$(df -h --output=source,avail,size,target | grep -e "^/" -e "Filesystem" | grep -ve "boot" -e "efi")" ;;
	2) gnome-disks ;;
	3) baobab ;;
esac

#printf "%s: %s\n" "$icon" "$(df -h "$1" | awk ' /[0-9]/ {print $4 "/" $2}')"
printf "%s: %s\n" "$icon" "$(df -h "$1" | awk ' /[0-9]/ {print $4}')"
