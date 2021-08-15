#!/bin/bash

# toggles default sound output device
default_sink=$(pacmd info | grep "Default sink name:" | cut -d ' ' -f4)

_usage() {
	echo "usage: padefault <command> [args]"
	echo "commands:"
	echo "    toggle-focus    cycles focused window audio device"
	echo "    toggle          cycles default audio device"
	echo "    mute            toggle mute on default device"
	echo "    mute-all        toggle mute on all outputs"
	echo "    mute-all-src    toggle mute on all inputs"
	echo "    volume [args]   sets default audio device volume"
	exit 0
}

padef_toggle_focus() {
	declare -A application_ids # application pid -> sink number
	declare -A application_idx # application pid -> sink index
	declare -A application_ico # application pid -> icon
	while IFS= read -r line; do
		while IFS=' ' read -a arr; do
			application_ids+=([${arr[0]}]=${arr[1]})
			application_idx+=([${arr[0]}]=${arr[2]})
			echo ${arr[@]}
		done <<< $(echo $line)
	done <<< "$(pacmd list-sink-inputs | awk '
		{
			if ($1 == "sink:") {
				sink=$2
			} else if ($1 == "application.process.id") {
				pid=substr($3, 2, length($3) - 2)
			} else if ($1 == "index:") {
				idx=$2
			} 

			if (sink != "" && pid != "" && idx != "") { 
				print pid " " sink " " idx
				pid=""
				sink=""
				idx=""
			}
		}')" # outputs pid sink pairs

	declare -a sinks # sink short names for move-to
	declare -A descs # sink description for notification
	while IFS= read -r line; do
		while IFS=' ' read -a arr; do
			sinks+=(${arr[0]})
			descs+=([${arr[0]}]="${arr[@]:1}")
		done <<< $(echo $line)
	done <<< "$(pactl list sinks | awk '{
		if ($1 == "Description:") {
			desc=substr($0, length($1)+2, length($0))
		} else if ($1 == "Name:") {
			name=$2
		}
		if (name != "" && desc != "") {
			print name " " desc
			name=""
			desc=""
		}
	}')" # outputs pid sink pairs

	# searching process trees for all related pids
	if [ -n "$1" ]; then
		wpid="$(xdotool search --onlyvisible --name "$1" getwindowpid)"
		if [ -z  "$wpid" ]; then
			wpid="$(xdotool search --onlyvisible --class "$1" getwindowpid)"
		fi
		if [ -z  "$wpid" ]; then
			exit 1
		fi
		wname="$(xdotool search --onlyvisible --name "$1" getwindowname)"
	else
		wname="$(xdotool getwindowfocus getwindowname)"
		wpid="$(xdotool getwindowfocus getwindowpid)"
	fi

	# fix for programs that are not direct controllers of the 
	# sink input
	case "$wname" in
		Cantata) pid="$(pgrep mpd)"       ;;
		*) pid="$wpid $(pgrep -P "$wpid")";;
	esac


	output="$wname"
	for app in ${!application_ids[@]}; do
		if [[ ! "$pid" =~ "$app" ]]; then
			continue
		fi
		
		output="$output (${app})\n"
		next_sink=-1
		for sink in ${!sinks[@]}; do
			if [ ${application_ids[$app]} -eq $sink ]; then
				next_sink=$(((sink + 1) % ${#sinks[@]}))
			fi
		done

		if [ $next_sink -ne -1 ]; then
			name="${sinks[$next_sink]}"
			desc="${descs[$name]}"
			pacmd move-sink-input "${application_idx[$app]}" "${name}"

			for sink in "${sinks[@]}"; do
				if [ "$sink" == "$name" ]; then
					output="$output[x] ${descs[$sink]}\n"
				else
					output="$output[ ] ${descs[$sink]}\n"
				fi
			done
				
			notify-send -a padefault -i "audio-speakers" "Switched Audio Output" "$output" -t 2000
		fi

	done
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
	toggle-focus|tf)   padef_toggle_focus "$2";;
	toggle|t)          padef_toggle      ;;
	volume|vol|v)      padef_volume "$2" ;;
	mute|m)            padef_mute        ;;
	mute-all|ma)       pa_mute_all       ;;
	mute-all-src|mas)  pa_mute_all source;;
	-h|help|--help|h)  _usage            ;;
	*)                 padef_toggle      ;;
esac

