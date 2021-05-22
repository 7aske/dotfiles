#!/usr/bin/env bash

default_sink="$(pacmd info | grep "Default sink name:" | cut -d ' ' -f4)"

pactl list sinks | grep -A7 "^[[:space:]]Name: $default_sink" | \
	tail -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,'
