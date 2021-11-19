#!/usr/bin/env bash

ZOOMSRC="$HOME/.zoomsrc" 
# Using -a flag displays all lectures regardless of the day
# Lectures should be set as a semicolon delimited string in env ZOOMS variable  
# eg. <title> [ - day ] < - link>;
# export ZOOMS="
# Lecture 1 - 2 - https://zoom.us/j/<id>?pwd=<pwd>"
[ -e "$ZOOMSRC" ]  && . "$ZOOMSRC"
if [ -z "$ZOOMS" ]; then
	echo "No valid lectures set in \$ZOOMS env variable"
	exit 1
fi

ALL=false
while getopts "a" arg; do
	case $arg in
		a) ALL=true ;;
	esac
done

shift $((OPTIND - 1))

day="$(date "+%w")"
if [ -n "$1" ]; then
	LECTURE="$(echo -e "$ZOOMS" | tr ';' '\n' | grep -i "$1" | cut -d"-" -f2)"
else
	LECTURE="$(echo -e "$ZOOMS" | tr ';' '\n' | awk -F'-' 'NF && ($2 == '$day' || NF == 2 || "'$ALL'" == "true") { print $0 }' | dmenu -i -l 10 | awk -F"-" '{print $3}')"
fi

if [ -n "$LECTURE" ]; then
	(setsid xdg-open "$LECTURE") &
fi
