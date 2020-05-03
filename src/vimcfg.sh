#!/usr/bin/env bash

prog="$(basename $0)"
dot_dir="$CODE/sh/dotfiles"

[ ! -d "$dot_dir" ] && echo "$prog: $dot_dir: no such file or directory" && exit 1

dotfile="$(find "$dot_dir" -maxdepth 3 -type f | grep -v ".git" | fzf --reverse --cycle )"

if [ -f "$dotfile" ]; then
    vim "$dotfile"
elif [ -n "$dotfile" ]; then
    echo "$prog: $dotfile: no such file or directory" && exit 1
fi
