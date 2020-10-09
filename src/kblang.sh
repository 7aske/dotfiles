#!/usr/bin/env bash

quick_layouts="us\nrs"

layout="$(cat <(echo -e $quick_layouts) <(localectl list-x11-keymap-layouts --no-pager) | dmenu -fn 'Fira Code-10' -p "layout:")"

if [ -n "$layout" ]; then
    variant="$(cat <(echo -e " ") <(localectl list-x11-keymap-variants "$layout") | dmenu -fn 'Fira Code-10' -p "$layout:")"
    if [ -n "$variant" ] && [ "$variant" != " " ]; then
        setxkbmap -layout "$layout" -variant "$variant"
    else
        setxkbmap -layout "$layout"
    fi
fi
