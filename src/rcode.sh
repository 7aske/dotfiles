#!/usr/bin/env bash

function show_help (){
	echo "usage "$(basename $0)" -?hpsv <-s|-d> <host> <repo>"
	echo "    -?,h         show this message and exit"
	echo "    -p <port>    ssh port used by rsync"
	echo "    -s <host>    source host"
	echo "    -d <host>    destination host"
}

# A POSIX getopts variable
OPTIND=1

repo=""
port=22
dest=""
src=""

while getopts "h?:p:s:d:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    p)  port=$OPTARG
        ;;
    s)  src=$OPTARG
        ;;
    d)  dest=$OPTARG
		echo $dest
        ;;
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

[ -n "$dest" ] && dest="$dest:"
[ -n "$src" ] && src="$src:"

if [ "$dest" != "$src" ] && [ -n "$1" ]; then
	rsync --progress -have "ssh -p $port" "$src$CODE/$1/" "$dest$CODE/$1/"
else
	show_help
	exit 1
fi

