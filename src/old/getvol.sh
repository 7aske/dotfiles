#!/usr/bin/env bash

default_sink=$(pactl info | grep "Default Sink:" | cut -d ' ' -f3)

pactl list sinks | grep -A7 "^[[:space:]]Name: $default_sink" | \
	tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
