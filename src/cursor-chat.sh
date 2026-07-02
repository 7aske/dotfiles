#!/usr/bin/env sh

CHAT_DIR="$(mktemp -d)"

cursor-agent --mode ask --workspace "$CHAT_DIR"  "$@"
