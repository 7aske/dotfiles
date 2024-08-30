#!/usr/bin/env bash

FOLDER="$1"
DEST="${DEST:-"/run/mount/sda1/cache"}"

_usage() {
	echo "usage: hddcache <folder>"
	echo "cache folder: DEST=$DEST"
	exit 0
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -gt 1 ]; then
	_usage
fi

if [ ! -e "$HOME/.cache/$FOLDER" ]; then
	echo "hddcache: $FOLDER: no such file or directory"
	exit 1
fi

if [ -L "$HOME/.cache/$FOLDER" ]; then
	echo "hddcache: $FOLDER: source folder is a symlink"
	exit 1
fi

mv "$HOME/.cache/$FOLDER" "$DEST/$FOLDER" \
	&& ln -sf "$DEST/$FOLDER" "$HOME/.cache/$FOLDER"
