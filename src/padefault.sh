#!/bin/bash

# toggles default sound output device

sinks=($(pactl list sinks | grep Name: | cut -d ' ' -f2 | grep -n ''))
names=($(pacmd list-sinks | grep alsa.name | cut -d '=' -f2 | tr -d ' "'))
default_sink=$(pacmd info | grep "Default sink name:" | cut -d ' ' -f4)
for sink in "${sinks[@]}"
do
    name=$(echo "$sink" | cut -d ':' -f2)
    index=$(echo "$sink" | cut -d ':' -f1)
    echo "$name" "$index"
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
