#!/usr/bin/env bash

FOLDER="$1"
DEST="${DEST:-"/run/mount/sda1/cache"}"

mv "$HOME/.cache/$FOLDER" "$DEST/$FOLDER" \
	&& ln -sf "$DEST/$FOLDER" "$HOME/.cache/$FOLDER"
