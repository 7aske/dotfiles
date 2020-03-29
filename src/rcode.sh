#!/usr/bin/env bash

repo=$1

declare src
declare dest

if [ "$2" = "-s" ]; then
	src="$3":"$CODE"/"$repo"
	dest="$CODE"/"$repo"
elif [ "$2" = "-d" ]; then
	src="$CODE"/"$repo"
	dest="$3":"$CODE"/"$repo"
else
	echo "Invalid second argument."
	exit 1
fi

rsync --progress -have ssh "$src" "$(dirname "$dest")"
