#!/usr/bin/env bash

prog="$(basename $0)"
find_flags=" -maxdepth 3 -type f "
find_cmd="find "
case "$1" in
    "--etc")  find_cmd="sudo find "; cfg_dir="/etc" ;;
    "--home") find_flags=" -maxdepth 1 -type f"; cfg_dir="$HOME" ;;
    *) cfg_dir="$CODE/sh/dotfiles" ;;
esac

[ -z "$EDITOR" ] &&  echo "$prog: EDITOR env variable not set" && exit 1
[ ! -d "$cfg_dir" ] && echo "$prog: $cfg_dir: no such file or directory" && exit 1
files="$(eval $find_cmd $cfg_dir $find_flags)"
config_file="$(echo $files | sed 's/\ /\n/g' | grep -v ".git" | fzf --reverse --cycle)"

if [ -f "$config_file" ]; then
    if [ -w "$config_file" ]; then
        eval "$EDITOR $config_file"
    else
        eval "sudo $EDITOR $config_file"
    fi
elif [ -n "$config_file" ]; then
    echo "$prog: $config_file: no such file or directory" && exit 1
fi
