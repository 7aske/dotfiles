#!/usr/bin/env bash

PROG="$(basename $0)"
[ ! -x "$(command -v git)" ] && echo -e "\e[1;31m$PROG: git: command not found\e[0m" && exit 2
[ -z "$CODE" ] && echo -e "\e[1;31m$PROG: CODE env variable not set\e[0m" && exit 2

CODEPULL_REPOS="${CODEPULL_REPOS:-"sh/dotfiles;sh/autosetup;uni;sh/scripts"}"

IFS=';' read -ra REPOS <<< "$CODEPULL_REPOS"

usage() {
    echo "usage: $PROG [options]"
	echo
    echo "options:"
	echo "  -A      pull all repos from CODE($CODE)"
    exit 1
}

_is_git_repo(){
	[ ! -d "$1" ] && return 1
	git -C "$1" rev-parse --is-inside-work-tree 2>/dev/null 1>/dev/null
}

git_pull() {
    echo -e "\e[32m$1\e[0m"
	DIR="$1"

	if ! _is_git_repo "$DIR"; then
		echo "$1: not a git repository"
		return 1
	fi

    git -C "$DIR" pull --no-stat 2>/dev/null | grep Updating | while read -r OUTPUT; do
        if [ -n "$DISPLAY" ]; then
            notify-send -u low -i git "$1" "$OUTPUT"
        else
            echo "$1" "$OUTPUT"
        fi
    done &
}

if [ "$1" == "-h" ]; then
	usage
elif [ "$1" == "-A" ]; then
	for REPO in $(cgs -d); do
		git_pull "$REPO"
	done
elif [ -z "$1" ]; then
    for REPO in "${REPOS[@]}"; do
		if [[ $REPO =~ ^/.* ]]; then
			git_pull "$REPO"
		else
			git_pull "$CODE/$REPO"
		fi
    done
else
    usage
fi
