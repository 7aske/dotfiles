#!/usr/bin/env bash
# Wrapper: apply active Taskwarrior profile, then run real taskwarrior-tui.
BIN_DIR="$(cd "$(dirname "$0")" && pwd)"
eval "$("$BIN_DIR/task-env" export)"
real="$("$BIN_DIR/task-env" real taskwarrior-tui)" || exit 127
exec "$real" "$@"
