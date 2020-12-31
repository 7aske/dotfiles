#!/usr/bin/env bash

case "$BLOCK_BUTTON" in
	1) $TERMINAL -e newsboat;;
	2) $TERMINAL -c floating -e vim ~/.config/newsboat/urls;;
	3) newsboat -x reload 2>/dev/null >/dev/null ;;
esac

UNREAD="$(newsboat -x print-unread | awk '{print $1}')"
if [ "$UNREAD" -eq 0 ]; then
	unset UNREAD
fi

echo "<span> $UNREAD</span>"
