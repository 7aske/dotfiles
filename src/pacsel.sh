#!/usr/bin/env bash

prog="$(basename $0)"

function usage(){
	echo "usage: $prog [query]"
	exit 1
}

if [ $# -eq 1 ] || [ "$1" = "-" ]; then
	package="$(yay -Ss "$1" | awk -e '$0 ~ /^[a-z]+/ {split($1, arr, "/"); print arr[2]}' | tac | dmenu -l 10)"
elif [ $# -eq 0 ]; then
	package="$(cat "-" | awk -e '$0 ~ /^[a-z]+/ {split($1, arr, "/"); print arr[2]}' |  tac | dmenu -l 10)"
else
	usage
fi

