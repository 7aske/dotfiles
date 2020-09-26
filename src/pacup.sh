#!/usr/bin/env bash

tempfile="/tmp/pacup"

function pacup_count(){
	if [ -f "$tempfile" ]; then
		wc -l "$tempfile" | cut -d' ' -f1
	else
		echo 0
	fi
}

function pacup_update(){
	if [ $UID != 0 ]; then
		echo "Must run as root"
		exit 1
	fi

	yay -Syy
	yay -Qu > "$tempfile"
}

function pacup_list(){
	cat "$tempfile" | sed -n '1!p' | cut -d' ' -f1,4 | column -o ' | ' -t
}

case "$1" in
	"-u") pacup_update ;;
	"-c") pacup_count  ;;
	"-l") pacup_list   ;;
	   *) pacup_update ;;
esac

