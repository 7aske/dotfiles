#!/usr/bin/env sh

[ -z "$CODE" ] && return 1

case $BLOCK_BUTTON in
    1) notify-send -i git "Repositories" "$(cgs)" ;;
    3) notify-send -i git "Repositories" "$(cgs -v)" ;;
esac

/usr/bin/cgs | wc -l

