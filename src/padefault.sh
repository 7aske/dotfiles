#!/bin/bash

# toggles default sound output device
default_sink=$(pactl info | grep "Default Sink:" | cut -d ' ' -f3)
notify_timeout="1000"
MAX_VOLUME="${MAX_VOLUME:-150}"

_usage() {
	echo "usage: padefault <command> [args]"
	echo "commands:"
	echo "    volume-focus [args] sets volume of the focused window"
	echo "    toggle-focus        cycles focused window audio device"
	echo "    toggle              cycles default audio device"
	echo "    mute                toggle mute on default device"
	echo "    mute-all            toggle mute on all outputs"
	echo "    mute-all-src        toggle mute on all inputs"
	echo "    volume [args]       sets default audio device volume"
	echo "    mic-volume [args]   sets default audio input volume"
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
		done <<< $(echo $line)
	done <<< "$(pactl list sink-inputs | awk '
		{
			if ($1 == "Sink:") {
				sink=$2
			} else if ($1 == "application.process.id") {
				pid=substr($3, 2, length($3) - 2)
			} else if ($1 == "Sink" && $2 == "Input") {
				idx=substr($3, 2)
			} 

			if (sink != "" && pid != "" && idx != "") { 
				print pid " " sink " " idx
				pid=""
				sink=""
				idx=""
			}
		}')" # outputs pid sink pairs

	declare -a sinks # sink short names for move-to
	declare -a indices # sink indexes
	declare -A descs # sink description for notification
	while IFS= read -r line; do
		while IFS=' ' read -a arr; do
			indices+=(${arr[0]})
			sinks+=(${arr[1]})
			descs+=([${arr[1]}]="${arr[@]:2}")
		done <<< $(echo $line)
	done <<< "$(pactl list sinks | awk '{
		if ($1 == "Description:") {
			desc=substr($0, length($1)+2, length($0))
		} else if ($1 == "Name:") {
			name=$2
		} else if ($1 == "Sink") {
			idx=substr($2, 2)
		}

		if (name ~ /alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio(_2)?__sink/) {
			name=""
		}

		if (desc ~ /(USB Audio S\/PDIF Output)|(USB Audio Speakers)/) {
			desc=""
		}

		if (name != "" && desc != "" && idx != "") {
			print idx " " name " " desc
			name=""
			desc=""
			idx=""
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
		Cantata*) pid="$(pgrep mpd)"       ;;
		*) pid="$wpid $(pgrep -P "$wpid")";;
	esac


	output="$wname"
	for app in ${!application_ids[@]}; do
		echo $app ${application_ids[$app]} ${application_idx[$app]}
		if [[ ! "$pid" =~ "$app" ]]; then
			continue
		fi
		
		output="$output (${app})\n"
		next_sink=-1
		index=0
		for sink in ${indices[@]}; do
			if [ ${application_ids[$app]} -eq $sink ]; then
				next_sink=$(((index + 1) % ${#indices[@]}))
			fi
			((index++))
		done

		if [ $next_sink -ne -1 ]; then
			name="${sinks[$next_sink]}"
			desc="${descs[$name]}"
			pactl move-sink-input "${application_idx[$app]}" "${name}"

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
	exit 0
}

padef_toggle() {
	declare -a sinks # sink short names for move-to
	declare -a indices # sink indexes
	declare -A descs # sink description for notification
	while IFS= read -r line; do
		while IFS=' ' read -a arr; do
			indices+=(${arr[0]})
			sinks+=(${arr[1]})
			descs+=([${arr[1]}]="${arr[@]:2}")
		done <<< $(echo $line)
	done <<< "$(pactl list sinks | awk '{
		if ($1 == "Description:") {
			desc=substr($0, length($1)+2, length($0))
		} else if ($1 == "Name:") {
			name=$2
		} else if ($1 == "Sink") {
			idx=substr($2, 2)
		}

		if (name ~ /alsa_output.usb-Generic_USB_Audio-00.HiFi__hw_Audio(_2)?__sink/) {
			name=""
		}

		if (desc ~ /(USB Audio S\/PDIF Output)|(USB Audio Speakers)/) {
			desc=""
		}

		if (name != "" && desc != "" && idx != "") {
			print idx " " name " " desc
			name=""
			desc=""
			idx=""
		}
	}')" # outputs pid sink pairs

	echo ${sinks[@]}

	output=""
	next_sink=-1
	index=0
	for sink in ${indices[@]}; do
		name="${sinks[$index]}"
		if [ $default_sink == $name ]; then
			next_sink=$(((index + 1) % ${#indices[@]}))
		fi
		((index++))
	done

	if [ $next_sink -ne -1 ]; then
		name="${sinks[$next_sink]}"
		desc="${descs[$name]}"
		pactl set-default-sink "${name}"

		for sink in "${sinks[@]}"; do
			if [ "$sink" == "$name" ]; then
				output="$output[x] ${descs[$sink]}\n"
			else
				output="$output[ ] ${descs[$sink]}\n"
			fi
		done

		notify-send -a padefault -i "audio-speakers" "Switched Audio Output" "$output" -t 2000
	fi
}

padef_volume() {
	vol="$(padef_get_vol "$default_sink")"
	vol=$((vol + ${1%%%}))
	if (( $vol > $MAX_VOLUME )); then
		pactl set-sink-volume "$default_sink" "$MAX_VOLUME%"
	else
		pactl set-sink-volume "$default_sink" "$1"
	fi
	icon="audio-volume-low"
	vol="$(padef_get_vol "$default_sink")"
	if [ "$vol" -ge 66 ]; then
		icon="audio-volume-high"
	elif [ "$vol" -ge 33 ]; then
		icon="audio-volume-medium"
	elif [ "$vol" -eq 0 ]; then
		icon="audio-off"
	fi
	notify-send -a padefault -i $icon -h "int:value:$vol" -h "string:synchronous:volume"  "volume" " $1" -t "$notify_timeout"
	exit 0
}

padef_mic_volume() {
	default_source=$(pactl info | grep "Default Source:" | cut -d ' ' -f3)
	vol="$(padef_get_mic_vol "$default_source")"
	# check only if we're increasing volume
	if [[ "$1" = +* ]] && (( $((vol + ${1%%%})) > $MAX_VOLUME )); then
		pactl set-source-volume "$default_source" "$MAX_VOLUME%"
		vol=$MAX_VOLUME
	else
		pactl set-source-volume "$default_source" "$1"
	fi

	icon="audio-volume-low"
	vol="$(padef_get_mic_vol "$default_source")"
	if [ "$vol" -ge 66 ]; then
		icon="audio-volume-high"
	elif [ "$vol" -ge 33 ]; then
		icon="audio-volume-medium"
	elif [ "$vol" -eq 0 ]; then
		icon="audio-off"
	fi
	notify-send -a padefault -i $icon -h "int:value:$vol" -h "string:synchronous:volume"  "volume" " $1" -t "$notify_timeout"
	exit 0
}

padef_spec_volume() {
	declare -A application_idx # application pid -> sink index
	while IFS= read -r line; do
		while IFS=' ' read -a arr; do
			application_idx+=([${arr[0]}]=${arr[1]})
		done <<< $(echo $line)
	done <<< "$(pactl list sink-inputs | awk '
		{
			if ($1 == "application.process.id") {
				pid=substr($3, 2, length($3) - 2)
			} else if ($1 == "Sink" && $2 == "Input") {
				idx=substr($3, 2)
			} 

			if (pid != "" && idx != "") { 
				print pid " " idx
				pid=""
				idx=""
			}
		}')" # outputs pid sink pairs

	# searching process trees for all related pids
	if [ -n "$1" ]; then
		wpid="$(xdotool search --name "$1" getwindowpid)"
		if [ -z  "$wpid" ]; then
			wpid="$(xdotool search --class "$1" getwindowpid)"
		fi
		if [ -z  "$wpid" ]; then
			exit 1
		fi
		wname="$(xdotool search --name "$1" getwindowname)"
	else
		exit 1
	fi


	# fix for programs that are not direct controllers of the 
	# sink input
	case "$wname" in
		Cantata*) pid="$(pgrep mpd)"       ;;
		*) pid="$wpid $(pgrep -P "$wpid")";;
	esac

	index=-1
	for app in ${!application_idx[@]}; do
		if [[ "$pid" =~ "$app" ]]; then
			index="${application_idx[$app]}"
			break
		fi
	done

	if [ $index -eq -1 ]; then
		exit 1
	fi

	vol="$(padef_get_sink_vol "$index")"
	vol=$((vol + ${2%%%}))
	if (( $vol > $MAX_VOLUME )); then
		pactl set-sink-input-volume "$index" "$MAX_VOLUME%"
	else
		pactl set-sink-input-volume "$index" "$2"
	fi
	icon="audio-volume-low"
	vol="$(padef_get_sink_vol "$index")"
	if [ "$vol" -ge 66 ]; then
		icon="audio-volume-high"
	elif [ "$vol" -ge 33 ]; then
		icon="audio-volume-medium"
	elif [ "$vol" -eq 0 ]; then
		icon="audio-off"
	fi

	notify-send -a padefault -i $icon -h "int:value:$vol" -h "string:synchronous:volume" \
		"volume" "$wname" -t "$notify_timeout"
	exit 0

}

padef_focus_volume() {
	declare -A application_idx # application pid -> sink index
	while IFS= read -r line; do
		while IFS=' ' read -a arr; do
			application_idx+=([${arr[0]}]=${arr[1]})
		done <<< $(echo $line)
	done <<< "$(pactl list sink-inputs | awk '
		{
			if ($1 == "application.process.id") {
				pid=substr($3, 2, length($3) - 2)
			} else if ($1 == "Sink" && $2 == "Input") {
				idx=substr($3, 2)
			} 

			if (pid != "" && idx != "") { 
				print pid " " idx
				pid=""
				idx=""
			}
		}')" # outputs pid sink pairs

	wname="$(xdotool getwindowfocus getwindowname)"
	wpid="$(xdotool getwindowfocus getwindowpid)"

	# fix for programs that are not direct controllers of the 
	# sink input
	case "$wname" in
		Cantata*) pid="$(pgrep mpd)"       ;;
		*) pid="$wpid $(pgrep -P "$wpid")";;
	esac

	index=-1
	for app in ${!application_idx[@]}; do
		if [[ "$pid" =~ "$app" ]]; then
			index="${application_idx[$app]}"
			break
		fi
	done

	if [ $index -eq -1 ]; then
		exit 1
	fi

	vol="$(padef_get_sink_vol "$index")"
	vol=$((vol + ${1%%%}))
	if (( $vol > $MAX_VOLUME )); then
		pactl set-sink-input-volume "$index" "$MAX_VOLUME%"
	else
		pactl set-sink-input-volume "$index" "$1"
	fi
	icon="audio-volume-low"
	vol="$(padef_get_sink_vol "$index")"
	if [ "$vol" -ge 66 ]; then
		icon="audio-volume-high"
	elif [ "$vol" -ge 33 ]; then
		icon="audio-volume-medium"
	elif [ "$vol" -eq 0 ]; then
		icon="audio-off"
	fi

	notify-send -a padefault -i $icon -h "int:value:$vol" -h "string:synchronous:volume" \
		"volume" "$wname" -t "$notify_timeout"
	exit 0

}

padef_get_vol() {
	sink="${1:-"$default_sink"}"
	pactl list sinks | grep -A7 "^[[:space:]]Name: $sink" | \
		tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
}

padef_get_mic_vol() {
	default_source=$(pactl info | grep "Default Source:" | cut -d ' ' -f3)
	pactl list sources | grep -A7 "^[[:space:]]Name: $default_source" | \
		tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
}

padef_get_sink_vol() {
	pactl list sink-inputs | grep -A10 "^Sink Input #$1" | \
		tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
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
	volume-specific|vs) padef_spec_volume  "$2" "$3";;
	volume-focus|vf)    padef_focus_volume "$2";;
	toggle-focus|tf)    padef_toggle_focus "$2";;
	toggle|t)           padef_toggle      ;;
	volume|vol|v)       padef_volume "$2" ;;
	mic-volume|mv)      padef_mic_volume "$2" ;;
	mute|m)             padef_mute        ;;
	mute-all|ma)        pa_mute_all       ;;
	mute-all-src|mas)   pa_mute_all source;;
	-h|help|--help|h)   _usage            ;;
	*)                  padef_toggle      ;;
esac

