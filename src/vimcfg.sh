#!/usr/bin/env bash


prog="$(basename $0)"
find_flags="-maxdepth 1 -type f"
find_cmd="find"
cfg_dir="$(find ${CODE_DOTFILES:-$CODE/sh/dotfiles} -maxdepth 3 -type f)"

while getopts ":hHecs" opt; do
    case $opt in
        e) find_cmd="sudo find"; cfg_dir="/etc" ;;
        H) cfg_dir="$cfg_dir $HOME/" ;;
        c) cfg_dir="$cfg_dir $HOME/.config" ;;
        s) cfg_dir="$cfg_dir $HOME/.local/bin/scripts";;
        h) echo "Usage: $prog -[eHcsh]"; exit 0 ;;
        \?) echo "$prog: invalid option -- '$OPTARG'"; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

#case "$1" in
#    "--etc")  find_cmd="sudo find "; cfg_dir="/etc" ;;
#    "--home") find_flags=" -maxdepth 1 -type f"; cfg_dir="$HOME" ;;
#    "--config") find_flags=" -maxdepth 2 -type f"; cfg_dir="$HOME/.config" ;;
#    "--scripts") find_flags=" -maxdepth 1 -type f"; cfg_dir="$HOME/.local/bin/scripts" ;;
#    *) cfg_dir="${CODE_DOTFILES:-$CODE/sh/dotfiles}" ;;
#esac

[ -z "$EDITOR" ] &&  echo "$prog: EDITOR env variable not set" && exit 1
#[ ! -d "$cfg_dir" ] && echo "$prog: $cfg_dir: no such file or directory" && exit 1
files="$($find_cmd $cfg_dir $find_flags)"


if [ ! -t 1 ]; then
	config_file="$(echo $files | sed 's/\ /\n/g' | grep -v ".git" | rofi -dmenu )"
else
	config_file="$(echo $files | sed 's/\ /\n/g' | grep -v ".git" | fzf --cycle --reverse )"
fi

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
