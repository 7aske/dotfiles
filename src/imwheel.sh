#!/usr/bin/env sh

if pidof -qx imwheel && [ $# -eq 0 ]; then
	echo "imwheel: already running"
	exit 1
fi

/usr/bin/imwheel "$@"
