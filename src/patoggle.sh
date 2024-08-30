#!/bin/sh

target="${1:-"sinks"}"

_toggle() {
	case $target in
		sinks) pactl set-sink-mute "$1" toggle ;;
		sources) pactl set-source-mute "$1" toggle ;;
	esac
}

for sink in $(pactl list $target short | awk '{print $1}'); do
    _toggle $sink
done
