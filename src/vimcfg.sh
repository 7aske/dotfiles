#!/usr/bin/env bash

prog="$(basename $0)"
find_flags="-maxdepth 3 -type f"
find_cmd="find"
case "$1" in
    "--etc")  find_cmd="sudo find "; cfg_dir="/etc" ;;
    "--home") find_flags=" -maxdepth 1 -type f"; cfg_dir="$HOME" ;;
    *) cfg_dir="$CODE/sh/dotfiles" ;;
esac

[ -z "$EDITOR" ] &&  echo "$prog: EDITOR env variable not set" && exit 1
[ ! -d "$cfg_dir" ] && echo "$prog: $cfg_dir: no such file or directory" && exit 1
files="$($find_cmd $cfg_dir $find_flags | sort)"

config_file="$(echo $files | sed 's/\ /\n/g' | grep -v ".git" | dmenu -fn 'Fira Code Medium-10' -f -i -l 10 )"

cmd="$EDITOR $config_file"
[ ! -w "$config_file" ] && cmd="sudo $EDITOR $config_file"

if [ -f "$config_file" ]; then
	if [ ! -t 1 ]; then
		$TERMINAL -e $cmd
	else
		$cmd
	fi
elif [ -n "$config_file" ]; then
    echo "$prog: $config_file: no such file or directory" && exit 1
fi
