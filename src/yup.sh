#!/usr/bin/env bash

tempfile="/tmp/yup"

YUP_UID="${SUDO_UID:-"$(id -u)"}"
YUP_GID="${SUDO_GID:-"$(id -g)"}"
YUP_USER="${SUDO_USER:-"$(whoami)"}"

function _pacup_write(){
	yay -Qu | sudo -u "$YUP_USER" tee "$tempfile"
}

function pacup_count(){
	if [ -f "$tempfile" ]; then
		cat "$tempfile" | sed -n '1!p' | wc -l
	else
		echo 0
	fi
}

function pacup_update(){
	yay -Syy
	_pacup_write
	sudo -u "$YUP_USER" chown "$YUP_UID:$YUP_GID" "$tempfile"
}

function pacup_list(){
	cat "$tempfile" | sed -n '1!p' | cut -d' ' -f1,4 | column -o ' | ' -t
}

function pacup_reset(){
	echo "" | sudo -u "$YUP_USER" tee "$tempfile"
}

case "$1" in
	"-u") pacup_update ;;
	"-r") _pacup_write ;;
	"-c") pacup_count ;;
	"-l") pacup_list ;;
	   *) yay && _pacup_write ;;
esac

