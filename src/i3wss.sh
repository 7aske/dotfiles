#!/usr/bin/env bash

WS="$(echo {1..9} | tr ' ' '\n' | dmenu -fn 'Fira Code-12' -p 'workspace: ')"

case "$1" in
	"move")        i3-msg "move container to workspace $WS" ;;
	"move-switch") i3-msg "move container to workspace $WS; workspace $WS" ;;
	*)             i3-msg "workspace $WS" ;;
esac
