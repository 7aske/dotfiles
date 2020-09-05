#!/usr/bin/env bash

function show_help (){
	echo "usage "$(basename $0)" -?hpsv <repo>"
	echo "    -?,h         show this message and exit"
	echo "    -p <port>    ssh port used by rsync"
	echo "    -s <host>    source host (default :\`hostname\`)"
	echo "    -d <host>    destination host (default :\`hostname\`)"
}

# A POSIX variable
OPTIND=1

# Initialize our own variables:
repo=""
port=22
dest=`hostname`
src=`hostname`

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

dest="$dest:"
src="$src:"

if [ "$dest" != "$src" ]; then
	rsync --progress -have "ssh -p $port" "$src$CODE/$1/" "$dest$CODE/$1/"
else
	show_help
	exit 1
fi

