#!/usr/bin/env sh

case "$BLOCK_BUTTON" in
	1) dunstctl set-paused toggle ;;
esac


PAUSED="$(dunstctl is-paused)"

if [ "$PAUSED" = "true" ]; then
	echo '<span color="#BF616A"> </span>'
else
	echo '<span color="#ffffff"> </span>'
fi

