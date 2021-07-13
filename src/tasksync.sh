#!/usr/bin/env bash 

_sync() {
	[ -z "$1" ] && return 1
	[ -z "$2" ] && return 1
	([ ! -e "$1" ] && [ ! -e "$2" ]) && return 1
	rsync -uptgzd --filter '+ /*.data' --filter '- /*/' "$1" "$2"
}

TASKSERVER="${TASKSEVER:-"7aske.com"}"
TASKSERVER_USER="${TASKSEVER_USER:-"nik"}"
SERVER_CACHE="$HOME/.cache/tasksync_server_taskdata"

[ ! -e "$(basename $SERVER_CACHE)" ] && mkdir "$(basename "$SERVER_CACHE")"

if [ -e "$SERVER_CACHE" ]; then
	. "$SERVER_CACHE"
else
	echo "Fetching SERVER_TASKDATA"
	SERVER_TASKDATA="$(ssh $TASKSERVER ". \$HOME/.profile; echo \$TASKDATA")"
	echo "SERVER_TASKDATA=$SERVER_TASKDATA" > "$SERVER_CACHE"
fi


[ -z "$SERVER_TASKDATA" ] && exit 1
[ -z "$TASKDATA" ]        && exit 1
[ -z "$TASKSERVER" ]      && exit 1

SERVER_FOLDER="$TASKSERVER_USER@$TASKSERVER:$SERVER_TASKDATA/"
LOCAL_FOLDER="$TASKDATA/"

if [ "$1" = "recv" ] || [ -z "$1" ]; then
	echo "$TASKSERVER -> $(hostname)"
	_sync "$SERVER_FOLDER" "$LOCAL_FOLDER" || exit 2
fi

if [ "$1" = "send" ] || [ -z "$1" ]; then
	echo "$TASKSERVER <- $(hostname)"
	_sync "$LOCAL_FOLDER" "$SERVER_FOLDER" 
fi
