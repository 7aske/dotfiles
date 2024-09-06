#!/usr/bin/env bash

icon=" "
echo "<span size='large'>$icon</span>"
while read button; do
    [ -e "$HOME/.local/share/dice.mp3" ] && paplay ~/.local/share/dice.mp3 &
    num="$((RANDOM % 20 + 1))"
    dice=(󰝯 󰡧 󰗪 󰗫 󰗭 󰗬)
    for i in ${dice[*]}; do
        echo "<span size='large'>$i </span>"
        sleep 0.1
    done
    echo "<span size='medium' rise='-3pt'>$num</span>"
    sleep 2
    echo "<span size='large'>$icon</span>"
done
