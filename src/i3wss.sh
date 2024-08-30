#!/usr/bin/env bash

prompt=""

case "$1" in
	"move")        prompt="send to";;
	"move-switch") prompt="move and switch to";;
	*)             prompt="go to";;
esac


WORKSPACES=$(i3-msg -t get_workspaces | jq | grep name | sed 's/.*:\ \"\(.*\)\".*/\1/g' | sort -r)

WS="$(echo $WORKSPACES | tr ' ' '\n' | dmenu -fn 'Fira Code-10' -p "$prompt: ")"

case "$1" in
	"move")        i3-msg "move container to workspace $WS" ;;
	"move-switch") i3-msg "move container to workspace $WS; workspace $WS" ;;
	*)             i3-msg "workspace $WS" ;;
esac
