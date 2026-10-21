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

if [ -d "$1/herdr_git_tui" ]; then
    share="$(dirname "$2")/share/herdr-git-tui"
    mkdir -p "$share"
    rm -rf "$share/herdr_git_tui"
    cp -r "$1/herdr_git_tui" "$share/"
    find "$share/herdr_git_tui" -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
fi

