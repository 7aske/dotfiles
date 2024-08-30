#!/usr/bin/env bash

prog="$(basename $0)"

function _usage (){
	echo "usage "$prog" -?hp <push|pull> <remote> <repo>"
	echo "    -?,h         show this message and exit"
	echo "    -p <port>    ssh port used by rsync"
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
    esac
done

shift $((OPTIND-1))

[ "${1:-}" = "--" ] && shift

cmd="$1"
remote="$2"
repo="$3"

if [ -z "$repo" ]; then
	cwd="$(pwd)"
	repo="${cwd//$CODE\//}"
fi

if [ "$cmd" != "pull" ] && [ "$cmd" != "push" ]; then
	_usage
fi

if [ -z "$cmd" ] || [ -z "$remote" ] || [ -z "$repo" ]; then
	_usage
fi

if ! [[ $repo =~ ^.*/$ ]]; then
	repo="$repo/"
fi

REMOTE_CODE="$(ssh -p $port $remote '. ~/.profile; echo $CODE')"
echo ssh -p $port $remote '. ~/.profile; echo $CODE'

if [ -z "$REMOTE_CODE" ]; then
	echo -e "$prog: $REMOTE_CODE: no such file or directory"
	_usage
fi

if [ -z "$repo" ]; then
	echo -e "$prog: $repo: no such file or directory"
	_usage
fi

if [ "$cmd" == "push" ]; then
	dest="$remote:"
elif [ "$cmd" == "pull" ]; then
	src="$remote:"
fi

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

