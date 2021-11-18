#!/usr/bin/env bash

# Lectures should be set as a semicolon delimited string in env ZOOMS variable  
# eg. <title> [ - day ] < - link>;
# export ZOOMS="
# Lecture 1 - 2 - https://zoom.us/j/<id>?pwd=<pwd>"
[ -e "$HOME/.profile" ]  && . "$HOME/.profile" 
[ -e "$HOME/.xprofile" ] && . "$HOME/.xprofile" 
if [ -z "$ZOOMS" ]; then
	echo "No valid lectures set in \$ZOOMS env variable"
	exit 1
fi

day="$(date "+%w")"
if [ -n "$1" ]; then
	(echo -e "$ZOOMS" | tr ';' '\n' | grep -i "$1" | cut -d"-" -f2 | xargs setsid xdg-open) &
else
	echo -e "$ZOOMS" | tr ';' '\n' | awk -F'-' '$2 == '$day' || NF == 2 { print $0 }' | dmenu -i -l 10 | awk -F"-" '{print $3}' | xargs xdg-open
fi

