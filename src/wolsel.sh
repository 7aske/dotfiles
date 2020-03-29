#!/bin/bash

mapfile -t options < ~/Code/sh/utils-sh/hosts
if [ "$?" -eq 1 ]; then
    echo "Could not read hosts file"
    exit 1
fi
for i in "${!options[@]}"
do 
    host="$(echo "${options[$i]}" | cut -d ' ' -f1)"
    ip="$(echo "${options[$i]}" | cut -d ' ' -f2)"
    mac="$(echo "${options[$i]}" | cut -d ' ' -f3)"
    printf "%d) %-10s %10s %10s\n" "$((i+1))" "$host" "$ip" "$mac"
done

declare reply

if [ -n "$1" ]; then
    reply=$1
else
    printf "%s" "Select the device: "
    read -r reply
fi
reply=$((reply-1))
if [ "$reply" -lt $(("${#options[@]}"+1)) ]; then
    host="$(echo "${options[$reply]}" | cut -d ' ' -f1)"
    ip="$(echo "${options[$reply]}" | cut -d ' ' -f2)"
    mac="$(echo "${options[$reply]}" | cut -d ' ' -f3)"
    wakeonlan "$mac" &> /dev/null
    printf "Waking up %s@%s\n" "$host" "$ip"
else
    echo "Invalid index"
fi

