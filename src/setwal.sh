#!/usr/bin/env sh

WALLPAPERS="${WALLPAPERS:-$HOME/Pictures/wallpaper}"
DEFAULT_WALLPAPER="${DEFAULT_WALLPAPER:-$HOME/.config/wallpaper}"
CMD="$(basename "$0")"

[ -z "$(command -v wal)" ] && echo "wal: command not found" && exit 2
[ -z "$(command -v sxiv)" ] && echo "sxiv: command not found" && exit 2

invalid_opt() {
    printf "%s: invalid argument '%s'\nTry '%s -h' for more information.\n" "$CMD" "$1" "$CMD"
}

setwal_usage() {
    echo "usage: $CMD [option]"
    echo "options:"
    printf "  %-14s%s\n" "-w <file>" "sets file as wallpaper"
    printf "  %-14s%s\n" "-l" "set on from wallpapers dir"
    printf "  %-14s%s\n" "-R" "sets a random wallpaper"
    printf "  %-14s%s\n" "-r" "reload current wallpaper"
    printf "  %-14s%s\n" "-h, --help" "shows this message"
    exit 2
}

random_wallpaper() {
    PICTURE="$(find "$WALLPAPERS" -printf "$WALLPAPERS/%f\n" | shuf -n 1)"
    set_wallpaper "$PICTURE"
}

reload_wallpaper() {
    set_wallpaper "$DEFAULT_WALLPAPER"
}

list_wallpapers() {
    PICTURE="$(find "$WALLPAPERS" -printf "$WALLPAPERS/%f\n" | sxiv -tio | sed '1q')"
    set_wallpaper "$PICTURE"
}

set_wallpaper() {
    if echo "$1" | grep '^/' >/dev/null; then
        PICTURE="$1"
    else
        PICTURE="$(pwd)/$1"
    fi
    [ ! -L "$PICTURE" ] && ln -sf "$PICTURE" "$DEFAULT_WALLPAPER"
    wal -c
    wal --backend wal -i "$PICTURE" >/dev/null 2>&1 &
}

if [ -z "$1" ]; then
    sxiv -t "$WALLPAPERS" &
    exit 0
fi

case "$1" in
"-h" | "--help") setwal_usage ;;
"-r") reload_wallpaper ;;
"-R") random_wallpaper ;;
"-l") list_wallpapers ;;
"-w") set_wallpaper "$2" ;;
*) invalid_opt "$1" ;;
esac && exit 1 || exit 0
