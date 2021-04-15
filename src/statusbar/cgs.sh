#!/usr/bin/env sh

[ -z "$CODE" ] && return 1

case $BLOCK_BUTTON in
    1) notify-send -i git "Repositories" "$(cgs)" ;;
    3) notify-send -i git "Repositories" "$(cgs -v)" ;;
esac

repos="$(/usr/bin/cgs | wc -l)"

if [ $repos -eq 0 ]; then
	exit 0
fi

echo "$repos"


