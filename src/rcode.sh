#!/usr/bin/env bash

prog="$(basename $0)"

function _usage (){
	echo "usage "$prog" -?hpsv <-s|-d> <repo>"
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
        _usage
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
if ! [[ $repo =~ ^.*/$ ]]; then
	repo="$repo/"
fi

if [ -n "$dest" ]; then
	REMOTE_CODE="$(ssh -p $port $dest '. ~/.profile; echo $CODE')"
elif [ -n "$src" ]; then
	REMOTE_CODE="$(ssh -p $port $src  '. ~/.profile; echo $CODE')"
fi

if [ -z "$REMOTE_CODE" ]; then
	echo -e "$prog: REMOTE_CODE: no such file or directory"
	_usage
fi

if [ -z "$repo" ]; then
	echo -e "$prog: $repo: no such file or directory"
	_usage
fi

[ -n "$dest" ] && dest="$dest:"
[ -n "$src" ] && src="$src:"

src="$src$CODE/$repo"
dest="$dest$REMOTE_CODE/$repo"

if [ ! -e "$CODE/$repo" ]; then
	echo -e "$prog: $repo: no such file or directory"
	_usage
fi

if [ "$dest" != "$src" ] && [ -n "$1" ]; then
	/usr/bin/env rsync --filter=':- .gitignore' --progress -have "ssh -p $port" "$src" "$dest"
else
	_usage
fi

