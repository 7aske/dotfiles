#!/usr/bin/env bash

prog="$(basename $0)"

function _usage (){
	echo "usage "$(basename $0)" -?hpsv <-s|-d> <repo>"
	echo "    -?,h         show this message and exit"
	echo "    -p <port>    ssh port used by rsync"
	echo "    -s <host>    source host"
	echo "    -d <host>    destination host"
	exit 2
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

repo="$1"
if ! [[ $repo =~ ^/.* ]]; then
	repo="$CODE/$repo/"
fi

if [ -z "$repo" ] || [ ! -e "$repo" ]; then
	echo -e "$prog: $repo: no such file or directory"
	_usage
fi

[ -n "$dest" ] && dest="$dest:"
[ -n "$src" ] && src="$src:"

if [ "$dest" != "$src" ] && [ -n "$1" ]; then
	/usr/bin/env rsync --progress -have "ssh -p $port" "$src$repo" "$dest$repo"
else
	_usage
	exit 1
fi

