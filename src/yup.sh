#!/usr/bin/env bash

tempfile="/tmp/pacup"

PACUP_UID="${SUDO_UID:-"$(id -u)"}"
PACUP_GID="${SUDO_GID:-"$(id -g)"}"
PACUP_USER="${SUDO_USER:-"$(whoami)"}"

function pacup_count(){
	if [ -f "$tempfile" ]; then
		cat "$tempfile" | sed -n '1!p' | wc -l
	else
		echo 0
	fi
}

function pacup_update(){
	sudo yay -Syy
	_pacup_write
	chmod 775 "$tempfile"
	chown "$PACUP_UID:$PACUP_GID" "$tempfile"
}

function _pacup_write(){
	yay -Qu | sudo -u "$PACUP_USER" tee "$tempfile"
}

function pacup_list(){
	cat "$tempfile" | sed -n '1!p' | cut -d' ' -f1,4 | column -o ' | ' -t
}

function pacup_reset(){
	echo "" | sudo -u "$PACUP_USER" tee "$tempfile"
}

case "$1" in
	"-u") pacup_update ;;
	"-r") pacup_reset ;;
	"-c") pacup_count ;;
	"-l") pacup_list ;;
	   *) yay && _pacup_write ;;
esac

