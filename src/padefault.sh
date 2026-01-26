#!/bin/bash

# toggles default sound output device
default_sink=$(pactl get-default-sink)
notify_timeout="1000"
MAX_VOLUME="${MAX_VOLUME:-150}"
MAX_MIC_VOLUME="${MAX_MIC_VOLUME:-100}"

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

declare -A speaker_volume_icons
speaker_volume_icons=(
    [overamplified]="audio-volume-high-danger"
    [high]="audio-volume-high"
    [medium]="audio-volume-medium"
    [low]="audio-volume-low"
    [mute]="audio-volume-muted"
)

declare -A mic_volume_icons
mic_volume_icons=(
    [high]="mic-volume-high"
    [medium]="mic-volume-medium"
    [low]="mic-volume-low"
    [mute]="mic-volume-muted"
)

padef_get_speaker_icon() {
    local vol="$1"
    local icon=${speaker_volume_icons[low]}
    if [ "$vol" -gt 100 ]; then
        icon=${speaker_volume_icons[overamplified]}
    elif [ "$vol" -ge 66 ]; then
        icon=${speaker_volume_icons[high]}
    elif [ "$vol" -ge 33 ]; then
        icon=${speaker_volume_icons[medium]}
    elif [ "$vol" -eq 0 ]; then
        icon=${speaker_volume_icons[mute]}
    fi
    echo "$icon"
}

padef_get_mic_icon() {
    local vol="$1"
    local icon=${mic_volume_icons[low]}
    if [ "$vol" -ge 66 ]; then
        icon=${mic_volume_icons[high]}
    elif [ "$vol" -ge 33 ]; then
        icon=${mic_volume_icons[medium]}
    elif [ "$vol" -eq 0 ]; then
        icon=${mic_volume_icons[mute]}
    fi
    echo "$icon"
}

# fix for programs that are not direct controllers of the 
# sink input
padef_get_fixed_pid() {
    local pid
    local wpid; wpid="$1"
	case "$wname" in
		Cantata*) pid="$(pgrep mpd)"       ;;
		*) pid="$wpid $(pgrep -P "$wpid" | tr '\n' ' ')";;
	esac

    echo "$pid"
}

padef_toggle_focus() {
	declare -A application_ids # application pid -> sink number
	declare -A application_idx # application pid -> sink index
	while IFS= read -r line; do
		while IFS=' ' read -r -a arr; do
			application_ids+=(["${arr[0]}"]="${arr[1]}")
			application_idx+=(["${arr[0]}"]="${arr[2]}")
		done <<< "$line"
    done <<< "$(pactl -fjson list sink-inputs | jq -r '.[] 
        | "\(.properties."application.process.id") \(.sink) \(.index)"')"

	declare -a sinks # sink short names for move-to
	declare -a indices # sink indexes
	declare -A descs # sink description for notification
	while IFS= read -r line; do
		while IFS=' ' read -r -a arr; do
			indices+=("${arr[0]}")
			sinks+=("${arr[1]}")
			descs+=([${arr[1]}]="${arr[@]:2}")
		done <<< "$line"
    done <<< "$(pactl -fjson list sinks | jq -cr '.[] 
        | select(all(.ports[]; .availability != "not available")) 
        | "\(.index) \(.name) \(.description)"')"

	# searching process trees for all related pids
    local wpid
    local wname
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

    local pid; pid="$(padef_get_fixed_pid "$wpid")"
    local output="$wname"
    local next_sink
    local index
    local name
    local desc
	for app in "${!application_ids[@]}"; do
		if [[ ! "$pid" =~ $app ]]; then
			continue
		fi
		
		output+=" (${app})\n"
		next_sink=-1
		index=0
		for sink in "${indices[@]}"; do
			if [ "${application_ids[$app]}" -eq "$sink" ]; then
				next_sink=$(((index + 1) % ${#indices[@]}))
			fi
			((index++))
		done

		if [ $next_sink -ne -1 ]; then
			name="${sinks[$next_sink]}"
			desc="${descs[$name]}"
			pactl move-sink-input "${application_idx[$app]}" "${name}"

			for sink in "${sinks[@]}"; do
                if [ "$sink" == "$default_sink" ]; then
                    output+=">"
                else
                    output+=" "
                fi

				if [ "$sink" == "$name" ]; then
					output+="[x] ${descs[$sink]}\n"
				else
					output+="[ ] ${descs[$sink]}\n"
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
		while IFS=' ' read -r -a arr; do
			indices+=("${arr[0]}")
			sinks+=("${arr[1]}")
			descs+=([${arr[1]}]="${arr[@]:2}")
		done <<< "$line"
    done <<< "$(pactl -fjson list sinks | jq -cr '.[] 
        | select(all(.ports[]; .availability != "not available")) 
        | "\(.index) \(.name) \(.description)"')"

	local output=""
	local next_sink=-1
	local index=0
	for sink in "${indices[@]}"; do
		name="${sinks[$index]}"
		if [ "$default_sink" == "$name" ]; then
			next_sink=$(((index + 1) % ${#indices[@]}))
		fi
		((index++))
	done

    local name
    local desc
	if [ $next_sink -ne -1 ]; then
		name="${sinks[$next_sink]}"
		pactl set-default-sink "${name}"

		for sink in "${sinks[@]}"; do
            desc="${descs[$sink]}"
			if [ "$sink" == "$name" ]; then
				output+="[x] ${desc}\n"
			else
				output+="[ ] ${desc}\n"
			fi
		done

		notify-send -a padefault -i "audio-speakers" "Switched Audio Output" "$output" -t 2000
	fi
}

padef_volume() {
	local vol
    # if the argument is relative add to current volume
    if [[ "$1" =~ [+-].* ]]; then
        vol=$(($(padef_get_vol "$default_sink") + ${1%%%}))
    else
        vol="${1%%%}"
    fi

	if (( "$vol" > "$MAX_VOLUME" )); then
		vol=$MAX_VOLUME
	fi

    pactl set-sink-volume "$default_sink" "$vol%"

    local icon; icon=$(padef_get_speaker_icon "$vol")
	notify-send -a padefault -i "$icon" -h "int:value:$vol" -h "string:synchronous:volume"  "volume" " $1" -t "$notify_timeout"
	exit 0
}

padef_mic_volume() {
    # TODO: replace with local default_source="$(pactl get-default-source)"
	local src; src=$(pactl info | grep "Default Source:" | cut -d ' ' -f3)
	local vol
    # if the argument is relative add to current volume
    if [[ "$1" =~ [+-].* ]]; then
        vol=$(($(padef_get_mic_vol "$src") + ${1%%%}))
    else
        vol="${1%%%}"
    fi

	if (( "$vol" > "$MAX_MIC_VOLUME" )); then
		vol=$MAX_MIC_VOLUME
	fi

    pactl set-source-volume "$src" "$vol%"

	notify-send -a padefault \
        -i "$(padef_get_mic_icon "$vol")" \
        -h "int:value:$vol" \
        -h "string:synchronous:volume" \
        "volume" " $1" -t "$notify_timeout"
	exit 0
}

padef_spec_volume() {
	declare -A application_idx # application pid -> sink index
	while IFS= read -r line; do
		while IFS=' ' read -r -a arr; do
			application_idx+=([${arr[0]}]=${arr[1]})
		done <<< "$line"
    done <<< "$(pactl -fjson list sink-inputs | jq -r '.[] 
        | "\(.properties."application.process.id") \(.index)"')"

	# searching process trees for all related pids
    local wpid
    local wname

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


    local pid; pid="$(padef_get_fixed_pid "$wpid")"
	local index=-1
	for app in "${!application_idx[@]}"; do
		if [[ "$pid" =~ $app  ]]; then
			index="${application_idx[$app]}"
			break
		fi
	done

    # not found
	if [ "$index" -eq -1 ]; then
		exit 1
	fi

	local vol
    # if the argument is relative add to current volume
    if [[ "$2" =~ [+-].* ]]; then
        vol=$(($(padef_get_vol_spec "$index") + ${2%%%}))
    else
        vol="${2%%%}"
    fi

	if (( "$vol" > "$MAX_VOLUME" )); then
		vol=$MAX_VOLUME
	fi

    pactl set-sink-input-volume "$index" "$vol%"

	notify-send -a padefault \
        -i "$(padef_get_speaker_icon "$vol")" \
        -h "int:value:$vol" -h "string:synchronous:volume" \
        -t "$notify_timeout" \
		"volume" "$wname $2"
	exit 0
}

padef_focus_volume() {
	declare -A application_idx # application pid -> sink index
	while IFS= read -r line; do
		while IFS=' ' read -r -a arr; do
			application_idx+=([${arr[0]}]=${arr[1]})
		done <<< "$line"
    done <<< "$(pactl -fjson list sink-inputs | jq -r '.[] 
        | "\(.properties."application.process.id") \(.index)"')"

	local wname; wname="$(xdotool getwindowfocus getwindowname)"
	local wpid; wpid="$(xdotool getwindowfocus getwindowpid)"
    local pid; pid="$(padef_get_fixed_pid "$wpid")"
	local index=-1
	for app in "${!application_idx[@]}"; do
		if [[ "$pid" =~ $app ]]; then
			index="${application_idx[$app]}"
			break
		fi
	done

	if [ "$index" -eq -1 ]; then
		exit 1
	fi

	local vol; vol=$(($(padef_get_vol_spec "$index") + ${1%%%}))
	if (( "$vol" > "$MAX_VOLUME" )); then
		pactl set-sink-input-volume "$index" "$MAX_VOLUME%"
		vol=$MAX_VOLUME
	else
		pactl set-sink-input-volume "$index" "$1"
	fi

    local icon; icon=$(padef_get_speaker_icon "$vol")
	notify-send -a padefault -i "$icon" -h "int:value:$vol" -h "string:synchronous:volume" \
		"volume" "$wname" -t "$notify_timeout"
	exit 0

}

padef_get_vol() {
	local sink="${1:-"$default_sink"}"
	pactl get-sink-volume "$1" | sed -n 's/.*: [^:]*: [^/]*\/ *\([0-9]\+\)%.*/\1/p'
}

padef_get_vol_spec() {
    pactl -fjson list sink-inputs | \
        jq -r '.[] | select(.index == '"$1"') | .volume."front-left".value_percent' | \
        sed 's/%$//'
}

padef_get_mic_vol() {
	local src; src="$(pactl get-default-source)"
	pactl get-source-volume "$src" | sed -n 's/.*: [^:]*: [^/]*\/ *\([0-9]\+\)%.*/\1/p'
}

padef_mute() {
	pactl set-sink-mute "$default_sink" toggle
	local icon;
    if [ "$(pactl -fjson list sinks | jq '.[] | select(.name == "'"$default_sink"'") | .mute')" == "true" ]; then
		icon="audio-volume-muted"
    else
        icon="$(padef_get_speaker_icon "$(padef_get_vol "$default_sink")")"
	fi
	notify-send -a padefault -i "$icon" "volume" "toggle mute\n$default_sink" -t 1000
	exit 0
}

_is_any_muted() {
	local target="${1:-"sink"}"
    local muted_count; muted_count=$(pactl -fjson list "${target}s" | \
        jq '[.[] | select(.mute)] | length')
    return $((muted_count > 0 ? 0 : 1))
}

pa_mute_all() {
	local target="${1:-"sink"}"
	_is_any_muted "$target"
	local action="$(($?))"

    case "$target" in
        "sink") icon="audio-volume-high" ;;
        "source") icon="audio-input-microphone-high" ;;
    esac

	for sink in $(pactl -fjson list "${target}s" | \
        jq '.[] | select(.name | test("^.*\\.monitor$") | not) | .index'); do
		pactl "set-${target}-mute" "$sink" $action
	done

    local message
    case $action in
        1)
            case "$target" in
                "sink") icon="audio-volume-muted" ;;
                "source") icon="audio-input-microphone-muted" ;;
            esac
            message="muted all ${target}s" ;;
        0)
            message="unmuted all ${target}s" ;;
    esac

	notify-send -a padefault --hint=int:transient:1 -i "$icon" "volume" "$message" -t 1000
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

