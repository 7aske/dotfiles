#!/usr/bin/env bash

BOOKS_DIR="${BOOKS_DIR:-"$HOME/Documents/books"}"

dir -1 "$BOOKS_DIR" | rofi -dmenu | xargs -I% $READER "$BOOKS_DIR/%"
