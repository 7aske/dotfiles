#!/usr/bin/env bash

i=0

count="$(dir -1 "$1" | wc -l)"
count="$((count / 10))"

for i in $(seq $count); do
    mkdir -p "$1/$i"
done

i=1
for file in $(dir -1 "$1"); do
    if [ $i -gt $count ]; then
        i=1
    fi

    cp "$1/$file" "$1/$i"
    i=$((i + 1))
done
