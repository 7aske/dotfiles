#!/usr/bin/env sh

setwal_usage(){
    echo -e "  setval.sh <file>\n"
    echo "      -l, list      lists all wallpapers in wallpaper dir"
    echo "      -h, --help    shows this message"
    exit 1
}

setwal_list(){
    find "$WALS" -printf "%f\n" | sort 
    exit 0
}

    
WALS="$HOME"/Pictures/wallpaper
WAL="$HOME"/.config/wallpaper

[ "$1" = "-l" ] || [ "$1" = "list" ] && setwal_list
[ "$1" = "-h" ] || [ "$1" = "--help" ] && setwal_usage
[ -z "$1" ] && setwal_usage

PIC="$(find "$WALS" -name "$1"\*)" 

[ ! -f "$PIC" ] && echo "$1: file not found" && exit 1

ln -sf "$PIC" "$WAL"
wal -c; wal --backend wal -i "$PIC"
