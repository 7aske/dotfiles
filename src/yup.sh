#!/usr/bin/env bash

tempfile="/tmp/yup"

function _root_check(){
	if [ "$EUID" != 0 ]; then
		sudo "$0" "$@"
		exit $?
	fi
}

function _pacup_write(){
	_root_check
	yay -Qu | grep -v "Avoid running yay as root/sudo" | tee "$tempfile"
}

function pacup_count(){
	if [ -f "$tempfile" ]; then
		cat "$tempfile" | wc -l
	else
		echo 0
	fi
}

function pacup_update(){
	yay -Syy
	_pacup_write
}

function pacup_list(){
	cat "$tempfile" | cut -d' ' -f1,4 | column -o ' | ' -t
}

function pacup_reset(){
	echo "" | tee "$tempfile"
}

case "$1" in
	"-u") pacup_update ;;
	"-r") _pacup_write ;;
	"-c") pacup_count ;;
	"-l") pacup_list ;;
	   *) yay && _pacup_write ;;
esac

