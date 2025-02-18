#!/usr/bin/env bash

/usr/bin/lutris -ojl | \
    jq -r '. | sort_by(.lastplayed) | reverse | .[] | .name + " (" + .slug + ")"' | \
    rofi -dmenu -i -p "game" | \
    sed -rn 's/.*\((.*)\)/\1/p' | \
    xargs -I% /usr/bin/lutris  "lutris:rungame/%"
