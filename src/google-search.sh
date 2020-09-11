#!/bin/sh
search=$(xclip -sel p -o | dmenu -p "google search:")
if [ -n "$search" ]; then
    xdg-open "https://www.google.com/search?q=$search"
fi
