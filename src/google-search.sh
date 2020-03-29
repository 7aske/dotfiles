#!/bin/sh
search=$(rofi -dmenu -p Search:)
if [ -n "$search" ]; then
    exo-open --launch WebBrowser "https://www.google.com/search?q=$search"
fi
