#!/usr/bin/env bash

prog="$(basename $0 .sh)"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ ! -e "$REPO_ROOT/.git" ] && exit 1

[ ! -e "$HOME/.config" ] && mkdir "$HOME/.config"

src="$REPO_ROOT/$1"
dest="$HOME/${2:-$1}"
if ! grep -q "$src" "$dest" 2>/dev/null; then
	echo "[ -e \"$src\" ] && . \"$src\"" >> "$dest"
fi
