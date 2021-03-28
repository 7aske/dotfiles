#!/usr/bin/env bash

filename="$(basename "$0")"
prog="${filename##*.}"

function _usage() {
	echo "usage: $prog [options] <repo>";
	echo "options:"
	echo -e "\t-b <branch>    set a branch to watch (default: current branch)"
	echo -e "\t-t <secs>      set a timeout between git fetch calls"
	exit 2;
}
function is_repo() { git -C "$1" rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null; }

OPTSTR=":hb:t:"

while getopts "$OPTSTR" ARG; do 
	case "${ARG}" in 
		h) _usage            ;;
		b) BRANCH="$OPTARG"  ;;
		t) TIMEOUT="$OPTARG" ;;
		:) echo "$prog: -$OPTARG requires an argument"
			_usage ;;
	esac
done

shift $((OPTIND-1))

if [[ $1 =~ ^/.* ]]; then
	REPO="$1"
else
	REPO="$CODE/$1"
fi


if [ ! -d "$REPO" ]; then echo "$prog: '$REPO' is not a directory" 1>&2 && exit 1; fi
if ! is_repo "$REPO"; then echo "$prog: '$REPO' is not a valid git repository" 1>&2 && exit 1; fi
procs="$(pgrep -fi -- "$0 $1" | wc -w)"
# dunno whats the deal here but everything greater than 2
# seems to indicate that the watch is running
if [ "$procs" -gt 2 ]; then
	>&2 echo "$prog: watch already running for '$1'"
	exit 1
fi

BRANCH="${BRANCH:-"$(git -C "$REPO" branch --show-current)"}"
TIMEOUT="${TIMEOUT:-"60"}"

echo "$prog: watching $REPO (origin/$BRANCH) with timeout of $TIMEOUT"

while true; do
	git -C "$REPO" fetch
	msg="$(git -C "$REPO" log HEAD..origin/$BRANCH --oneline)"
	count="$(echo "$msg" | wc -l)"

	if [  -n "$msg" ]; then
		notify-send -u normal -i git "$REPO($BRANCH) commits: $count" "\n$msg"
	fi

	sleep "$TIMEOUT"
done
