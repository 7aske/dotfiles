#!/bin/sh

for sink in $(pactl list sinks | grep Sink | awk '{print $2}' | cut -d '#' -f2)
do
    pactl set-sink-mute "$sink" toggle
done
