#!/usr/bin/env bash

WORKSPACES=$(i3-msg -t get_workspaces | jq | grep name | sed 's/.*:\ \"\(.*\)\".*/\1/g' | sort)

WS="$(echo $WORKSPACES | tr ' ' '\n' | dmenu -fn 'Fira Code-12' -p 'workspace: ')"

case "$1" in
	"move")        i3-msg "move container to workspace $WS" ;;
	"move-switch") i3-msg "move container to workspace $WS; workspace $WS" ;;
	*)             i3-msg "workspace $WS" ;;
esac
