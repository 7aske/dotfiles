#!/usr/bin/env bash

DESKFILE="/tmp/desk"
[ ! -e "$DESKFILE" ] && touch "$DESKFILE"
[ -z "$(command -v "idasen-controller")" ] && exit 127

desk_move_to() {
	height="$(dmenu -p height -f)"
	[ -z "$height" ] && return 1
	idasen-controller --forward --move-to "$height"
}

desk_stand() {
	idasen-controller --forward --move-to stand
}

desk_sit() {
	idasen-controller --forward --move-to sit
}

desk_mon() {
	idasen-controller --monitor
}

desk_down() {
	curr="$(sed '/^$/d' "$DESKFILE" | tail -n 1 | last_deskfile_entry)"
	curr="${curr%%mm}"
	delta=${1:-50}
	[ -z "$curr" ] && return 1
	((amount = curr - delta))
	idasen-controller --forward --move-to $amount
}

desk_up() {
	curr="$(sed '/^$/d' "$DESKFILE" | tail -n 1 | last_deskfile_entry)"
	curr="${curr%%mm}"
	delta=${1:-50}
	[ -z "$curr" ] && return 1
	((amount = curr + delta))
	idasen-controller --forward --move-to $amount
}

desk_mon_last() {
	tail -f "$DESKFILE" | while read line; do
		echo $line | last_deskfile_entry
	done
}

last_deskfile_entry() {
	awk 'match($0, /[Hh]eight:\s+[0-9]+mm/) {str=substr($0, RSTART, RLENGTH); $0=str ;print $2}'
}

case $1 in
	move-to)  desk_move_to  ;;
	stand)    desk_stand    ;;
	sit)      desk_sit      ;;
	mon)      desk_mon      ;;
	mon-last) desk_mon_last ;;
	down)     desk_down $2  ;;
	up)       desk_up   $2  ;;
esac
