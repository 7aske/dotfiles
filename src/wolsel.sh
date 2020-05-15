#!/bin/bash

prog="$(basename $0)"

hosts="$HOME/.local/etc/hosts"

[ ! -e "$hosts" ] && echo "$prog: $hosts: no such file or directory" && exit 1


mapfile -t options < <(sed -e '/^#.*/d' -e '/^[[:space:]]*$/d' "$hosts")

if [ "$?" -eq 1 ]; then
    echo "$prog: could not read hosts file"
    exit 1
fi

for i in "${!options[@]}"; do 
    host="$(echo "${options[$i]}" | awk '{print $1}')"
    ip="$(echo "${options[$i]}" | awk '{print $2}')"
    mac="$(echo "${options[$i]}" | awk '{print $3}')"
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
    host="$(echo "${options[$reply]}" | awk '{print $1}')"
    ip="$(echo "${options[$reply]}" | awk '{print $2}')"
    mac="$(echo "${options[$reply]}" | awk '{print $3}')"
    wakeonlan "$mac" &> /dev/null
    printf "Waking up %s@%s\n" "$host" "$ip"
else
    echo "Invalid index"
fi

