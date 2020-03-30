#!/usr/bin/env sh

WALLPAPERS="${WALLPAPERS:-$HOME/Pictures/wallpaper}"
DEFAULT_WALLPAPER="${DEFAULT_WALLPAPER:-$HOME/.config/wallpaper}"

[ -z "$(command -v wal)" ] && echo "wal: command not found" && exit 2
[ -z "$(command -v sxiv)" ] && echo "sxiv: command not found" && exit 2

setwal_usage() {
    echo "  setval.sh"
    echo ""
    echo "      -w <file>     sets file as wallpaper"
    echo "      -l            set on from wallpapers dir"
    echo "      -R            sets a random wallpaper"
    echo "      -h, --help    shows this message"
    exit 2
}


[ "$1" = "-h" ] || [ "$1" = "--help" ] && setwal_usage

if [ -z "$1" ];then
    sxiv -t "$WALLPAPERS" &
    exit 0
fi

if [ "$1" = "-R" ]; then
    PICTURE="$(find "$WALLPAPERS" -printf "$WALLPAPERS/%f\n" | shuf -n 1)"
    setwal -w "$PICTURE" && exit 0 || exit 1
fi

if [ "$1" = "-l" ]; then
    # PICTURE="$(find "$WALLPAPERS" -printf "$WALLPAPERS/%f\n" | sort | fzf --reverse --cycle)"
    PICTURE="$(find "$WALLPAPERS" -printf "$WALLPAPERS/%f\n" | sxiv -tio | sed '1q')"
    setwal -w "$PICTURE" && exit 0 || exit 1
fi

if [ $# -eq 2 ] && [ "$1" = "-w" ] && [ -f "$2" ]; then
    if echo "$2" | grep '^/' >/dev/null; then
        PICTURE="$2"
    else
        PICTURE="$(pwd)/$2"
    fi

    ln -sf "$PICTURE" "$DEFAULT_WALLPAPER"
    wal -c
    wal --backend wal -i "$PICTURE" && exit 0 || exit 1
else
    setwal_usage
fi
