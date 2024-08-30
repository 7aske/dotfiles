#!/usr/bin/env bash

# Select package manager to use
PACMAN="${PACMAN:-"yay"}"

tempfile="/tmp/yup"

function _root_check(){
	if [ "$EUID" != 0 ]; then
		if [ -t 1 ]; then 
			sudo "$0" "$@"
		else
			pkexec "$0" "$@"
		fi

		exit $?
	fi
}

function _pacup_write(){
	_root_check -r
	$PACMAN -Qu | grep -v "Avoid running $PACMAN as root/sudo" | sudo tee "$tempfile"
}

function pacup_count(){
	if [ -f "$tempfile" ]; then
		cat "$tempfile" | wc -l
	else
		echo 0
	fi
}

function pacup_update(){
	$PACMAN -Syy
	_pacup_write
}

function pacup_list(){
	cat "$tempfile" | column -o ' ' -t
}

function pacup_reset(){
	echo "" | tee "$tempfile"
}

while getopts "urcl" arg; do
	case "$arg" in
		u) pacup_update ;;
		r) _pacup_write ;;
		c) pacup_count  ;;
		l) pacup_list   ;;
	esac && exit 0
done

$PACMAN -Syyu && _pacup_write
