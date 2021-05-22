#!/bin/bash

# toggles default sound output device
default_sink=$(pacmd info | grep "Default sink name:" | cut -d ' ' -f4)

_usage() {
	echo "usage: padefault <command> [args]"
	echo "commands:"
	echo "    toggle          cycles default audio device"
	echo "    mute            mutes default device"
	echo "    volume [args]   sets default audio device volume"
	exit 0
}

padef_toggle() {
	sinks=($(pactl list sinks | grep Name: | cut -d ' ' -f2 | grep -n ''))
	names=($(pacmd list-sinks | grep alsa.name | cut -d '=' -f2 | tr -d ' "'))
	for sink in "${sinks[@]}"
	do
		name=$(echo "$sink" | cut -d ':' -f2)
		index=$(echo "$sink" | cut -d ':' -f1)
		if [ "$name" == "$default_sink" ]
		then
			if [ "${#sinks[@]}" == "$index" ]
			then
				pactl set-default-sink "$(echo "${sinks[0]}" | cut -d ':' -f2)"
				notify-send 'Default Audio Device' "${names[0]}" -t 1500
			else
				pactl set-default-sink "$(echo "${sinks[$index]}" | cut -d ':' -f2)"
				notify-send 'Default Audio Device' "${names[$index]}" -t 1500
			fi
		fi

	done
	exit 0
}

padef_volume() {
	pactl set-sink-volume "$default_sink" "$1"
	notify-send  "volume" " $1 ($(getvol)%)" -t 500
	exit 0
}

padef_mute() {
	pactl set-sink-mute "$default_sink"
	notify-send "volume" "toggle mute" -t 500
	exit 0
}

case "$1" in 
	toggle|t) padef_toggle ;;
	volume|vol|v) padef_volume "$2" ;;
	mute|m) padef_mute ;;
	-h|help|h) _usage ;;
	*) padef_toggle ;;
esac

