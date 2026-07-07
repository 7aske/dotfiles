#!/usr/bin/env sh

CHAT_DIR="$HOME/.agent-chat"

[ -e "$CHAT_DIR" ] || mkdir -p "$CHAT_DIR"

kitty --override background_opacity=1 --class floating cursor-agent --mode ask --workspace "$CHAT_DIR" "$@"
