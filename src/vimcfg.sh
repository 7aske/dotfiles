#!/usr/bin/env bash


prog="$(basename "$0")"
find_flags="-maxdepth 1 -type f"
find_cmd="find"
_code_dotfiles="${CODE_DOTFILES:-$CODE/sh/dotfiles}"
files="$(git -C "$_code_dotfiles" ls-files | xargs -I{} echo "$_code_dotfiles/{}")"

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

[ -z "$EDITOR" ] &&  echo "$prog: EDITOR env variable not set" && exit 1
files="$files$($find_cmd $cfg_dir $find_flags)"


if [ ! -t 1 ]; then
	config_file="$(echo "$files" | sed 's/\ /\n/g' | grep -v ".git" | rofi -dmenu)"
else
	config_file="$(echo "$files" | sed 's/\ /\n/g' | grep -v ".git" | fzf --cycle --reverse --preview 'bat --style=numbers --color=always --line-range :100 {}' --preview-window=bottom:60%)"
fi

if [ -z "$config_file" ]; then
    exit 0
fi

git_root=""
if git -C "$(basename "$config_file")" rev-parse --is-inside-work-tree &>/dev/null; then
    git_root="$(git -C "$(basename "$config_file")" rev-parse --show-toplevel)"
fi

[ ! -w "$config_file" ] && exit 1

cmd="$EDITOR $config_file"
[ ! -w "$config_file" ] && cmd="sudo $EDITOR $config_file"

if [ -f "$config_file" ]; then
	if [ ! -t 1 ]; then
        if [ -n "$git_root" ]; then
            $TERMINAL -d "$git_root" -e $cmd
        else
            $TERMINAL -e $cmd
        fi
	else
        if [ -n "$git_root" ]; then
            cd "$git_root" && $cmd
        else 
            $cmd
        fi
	fi
elif [ -n "$config_file" ]; then
    echo "$prog: $config_file: no such file or directory" && exit 1
fi
