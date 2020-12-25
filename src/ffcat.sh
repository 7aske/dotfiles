#!/usr/bin/env bash

list="list-$RANDOM.txt"

out="${1:-$(basename "$PWD")}"

find . -name \*.mp4 -printf "'%P'\n" | sort | awk '{print "file " $0}' > "$list"

ffmpeg -f concat -safe 0 -i "$list" -c copy "$out.mp4"

rm "$list"
