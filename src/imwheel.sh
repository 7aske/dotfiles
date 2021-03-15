#!/usr/bin/env sh

if pidof -qx imwheel; then
	echo "imwheel: already running"
	exit 1
fi

/usr/bin/imwheel
