#!/bin/bash

# toggles default sound output device
default_sink=$(pacmd info | grep "Default sink name:" | cut -d ' ' -f4)

_usage() {
	echo "usage: padefault <command> [args]"
	echo "commands:"
	echo "    toggle          cycles default audio device"
	echo "    mute            toggle mute on default device"
	echo "    mute-all        toggle mute on all outputs"
	echo "    mute-all-src    toggle mute on all inputs"
	echo "    volume [args]   sets default audio device volume"
	exit 0
}

padef_toggle() {
	declare -A sinks
	index=0
	while IFS= read -r line; do
		sinks+=([$index]="$(echo $line | cut -d ':' -f2)")
		index=$((index + 1))
	done <<< "$(pactl list sinks | grep Name: | cut -d ' ' -f2 | grep -n '')"

	declare -A names
	index=0
	while IFS= read -r line; do
		names+=([$index]="$line")
		index=$((index + 1))
	done <<< "$(pactl list sinks | grep Description: | cut -d ':' -f2 | sed -e 's/^[ \t]*//')"

	output=""

	next_index=-1
	for index in "${!sinks[@]}"; do
		name=${sinks[$index]}
		if [ "$name" == "$default_sink" ]; then
			next_index="$(((index + 1) % ${#sinks[@]}))"
			break;
		fi
	done

	if [ $next_index -eq -1 ]; then
		exit 1
	fi

	pactl set-default-sink "${sinks[$next_index]}"

	for index in "${!sinks[@]}"; do
		if [ "$next_index" == "$index" ]; then
			output="$output[x] ${names[$index]}\n"
		else
			output="$output[ ] ${names[$index]}\n"
		fi
	done

	printf "$output"
	notify-send -a padefault -i audio-speakers 'Default Audio Device' "$output" -t 1500
	exit 0
}

padef_volume() {
	pactl set-sink-volume "$default_sink" "$1"
	icon="audio-volume-low"
	vol="$(getvol)"
	if [ "$vol" -ge 66 ]; then
		icon="audio-volume-high"
	elif [ "$vol" -ge 33 ]; then
		icon="audio-volume-medium"
	elif [ "$vol" -eq 0 ]; then
		icon="audio-off"
	fi
	notify-send -a padefault -i $icon -h "int:value:$vol" -h "string:synchronous:volume"  "volume" " $1" -t 500
	exit 0
}

padef_mute() {
	pactl set-sink-mute "$default_sink" toggle
	icon="audio-on"
	if [ $(pactl list sinks | grep "Name: $default_sink" -A6 | tail -1 | awk '{print $2}')"" == "yes" ]; then
		icon="audio-off"
	fi
	notify-send -a padefault -i "$icon" "volume" "toggle mute\n$default_sink" -t 1000
	exit 0
}

_is_any_muted() {
	target="${1:-"sink"}"
	for mute in $(pactl list "${target}s" | grep Mute | awk '{print $2}'); do
		if [ "$mute" == "yes" ]; then
			return 0
		fi
	done
	return 1

}

pa_mute_all() {
	target="${1:-"sink"}"
	_is_any_muted "$target"
	action="$(($?))"
	for sink in $(pactl list "${target}s" short | awk '{print $1}'); do
		pactl "set-${target}-mute" "$sink" $action
	done
	icon="audio-speakers"
	if [ "$target" == "source" ]; then
		icon="audio-recorder"
	fi
	notify-send -a padefault --hint=int:transient:1 -i "$icon" "volume" "toggle mute" -t 1000
}

case "$1" in 
	toggle|t)          padef_toggle      ;;
	volume|vol|v)      padef_volume "$2" ;;
	mute|m)            padef_mute        ;;
	mute-all|ma)       pa_mute_all       ;;
	mute-all-src|mas)  pa_mute_all source;;
	-h|help|--help|h)  _usage            ;;
	*)                 padef_toggle      ;;
esac

