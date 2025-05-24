#!/usr/bin/env bash

CUR="$(archlinux-java get)"

if [ -t 0 ]; then
    MENU_CMD="fzf --prompt 'Select Java version ($CUR)'"
else
    MENU_CMD="rofi -dmenu -i -p 'Select Java version ($CUR)'"
fi

VER="$(archlinux-java status | awk 'NR != 1 && "'$CUR'" != $1 { print $1 }' | eval "$MENU_CMD")"

if [ -n "$VER" ]; then
    if [ -t 0 ]; then
        sudo archlinux-java set "$VER"
    else
        pkexec archlinux-java set "$VER"
    fi
fi
