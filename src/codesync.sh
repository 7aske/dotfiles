#!/usr/bin/env bash

SSH_OPT="${SSH_OPT:-"ssh"}"

RSYNC_OPTS="${RSYNC_OPTS:-"--progress"}"

while getopts ":hH:e:" arg; do
	case $arg in
		e) SSH_OPT="$OPTARG";;
		D) RSYNC_OPTS="${RSYNC_OPTS} --delete";;
		H) HOST="$OPTARG";;
		:) echo "codesync: -$arg requires and argument"
			exit 2;;
	esac
done

if [ -z "$HOST" ]; then 
	echo "codesync: HOST is not valid or empty"
	exit 2
fi

HOST_CODE="$($SSH_OPT $HOST 'source .profile; echo $CODE')"

if [ -z "$HOST_CODE" ]; then
	echo "codesync: HOST_CODE is not valid or empty"
	exit 2
fi

if [ -z "$CODE" ] || [ ! -d "$CODE" ]; then
	echo "codesync: CODE is not valid or empty"
	exit 2
fi

rsync -havz "$RSYNC_OPTS" -e "$SSH_OPT" "$HOST:$HOST_CODE/" "$CODE/"
