#!/usr/bin/env bash

filename="$(basename "$0")"
prog="${filename##*.}"

function _usage(){ echo "usage: $prog <coderepo> [branch]"; exit 2; }
function is_repo() { git -C "$1" rev-parse --is-inside-work-tree 2>&1>/dev/null; }

[ -z "$1" ] && _usage

REPO="$CODE/$1"

if [ ! -d "$REPO" ]; then echo "$prog: '$REPO' is not a directory" 1>&2 && exit 1; fi
if ! is_repo "$REPO"; then echo "$prog: '$REPO' is not a valid git repository" 1>&2 && exit 1; fi

branch="${2:-"$(git -C "$REPO" branch --show-current)"}"

echo "$prog: watching $1/$branch"

while true; do
	git -C "$REPO" fetch
	msg="$(git -C "$REPO" log HEAD..origin/$branch --oneline)"
	count="$(echo "$msg" | wc -l)"

	if [  -n "$msg" ]; then
		notify-send -u normal -i git "$1/$branch ($count)" "\n$msg"
	fi

	sleep 60
done
