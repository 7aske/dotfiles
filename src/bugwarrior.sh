#!/usr/bin/env bash
# Wrapper: apply active Taskwarrior profile, then run bugwarrior / bugwarrior-pull.
BIN_DIR="$(cd "$(dirname "$0")" && pwd)"
eval "$("$BIN_DIR/task-env" export)"

real="$("$BIN_DIR/task-env" real bugwarrior 2>/dev/null)" \
	|| real="$("$BIN_DIR/task-env" real bugwarrior-pull 2>/dev/null)" \
	|| {
		echo "bugwarrior: neither bugwarrior nor bugwarrior-pull found on PATH" >&2
		exit 127
	}

exec "$real" "$@"
