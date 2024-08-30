#!/usr/bin/env bash

usage() {
    echo "install.sh <input> <output>" && exit 2
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage

for f in "$1"/*.sh; do
    base=$(basename "$f" | cut -d "." -f 1)
    [ -f "$2/$base" ] && rm -v "$2/$base"
done
