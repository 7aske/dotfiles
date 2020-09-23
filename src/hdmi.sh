#!/usr/bin/env sh

MODE=${2:-"same-as"}

PRIMARY="$(xrandr | grep primary | cut -d' ' -f1)"
DISPL="${DISPL:-"HDMI-1"}"

if [ "$1" = "on" ]; then
    xrandr --output "$PRIMARY" --auto --output "$DISPL" --auto "--$MODE" "$PRIMARY"
elif [ "$1" = "off" ]; then
    xrandr --output "$DISPL" --off
fi
