#!/usr/bin/env sh

MODE=${2:-"same-as"}


_usage() {
	echo "$0: host $(hostname) not supported"
	exit 2
}

_handle_mariner() {
	MIRROR="${MIRROR:-"HDMI-2"}"
	TV="${TV:-"HDMI-1"}"
	if [ "$1" = "on" ]; then
		xrandr --output "$TV" --auto --same-as "$MIRROR"
	elif [ "$1" = "off" ]; then
		xrandr --output "$TV" --off
	fi
}

_handle_juno() {
	PRIMARY="$(xrandr | grep primary | cut -d' ' -f1)"
	MONITOR="$(xrandr --current | sed -n -e '/connected [^primary]/p' | cut -d ' ' -f1 | head -1)"
	if [ "$1" = "on" ]; then
		xrandr --output "$MONITOR" --mode "1920x1080" "--$MODE" "$PRIMARY" --scale '1.500x1.666'
	elif [ "$1" = "off" ]; then 
		xrandr --output "$MONITOR" --off
	fi
}

case $(hostname) in
	juno) _handle_juno $@ ;;
	mariner) _handle_mariner $@ ;;
	*) 
esac 
