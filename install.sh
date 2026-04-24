#!/usr/bin/env bash

usage() {
    echo "install.sh <input> <output>" && exit 2
}

[ -z "$1" ] && usage
[ -z "$2" ] && usage

[ ! -e "$2" ] && mkdir -p "$2"

for f in "$1"/*.{sh,py}; do
    base=$(basename "$f"  | cut -d "." -f 1)
    
    cp -v "$f" "$2/$base" || echo "error: unable to copy $f to $2"
    chmod u+x "$2/$base"

    # install bash completion if exists
    ./complete.sh "$base"
done

