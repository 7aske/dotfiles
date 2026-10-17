#!/usr/bin/env bash
# Resolve Taskwarrior profile -> TASKRC / TASKDATA.
# Profile name is stored in ~/.taskprofile (override with TASK_PROFILE_FILE).
#
# Usage:
#   task-env                     # pick profile with fzf/rofi
#   task-env set [profile]       # same; optional profile name skips the menu
#   task-env <profile>           # set profile directly
#   eval "$(task-env export)"    # export TASK_PROFILE, TASKRC, TASKDATA
#   task-env profile             # print current profile name
#   task-env list                # list known profiles
#   task-env real <command>      # path to real binary, skipping ~/.local/bin wrappers

TASK_PROFILE_FILE="${TASK_PROFILE_FILE:-$HOME/.taskprofile}"

_task_env_paths() {
	case "$1" in
	personal)
		TASKRC="${HOME}/.config/taskrc"
		TASKDATA="${HOME}/.config/task"
		;;
	work)
		TASKRC="${HOME}/.config/taskrc-work"
		TASKDATA="${HOME}/.config/task-work"
		;;
	*)
		echo "task-env: unknown profile '$1' (known: personal, work)" >&2
		return 1
		;;
	esac
}

_task_env_read() {
	local profile=""
	if [ -r "$TASK_PROFILE_FILE" ]; then
		profile="$(tr -d '[:space:]' <"$TASK_PROFILE_FILE")"
		profile="${profile#export TASK_PROFILE=}"
		profile="${profile#TASK_PROFILE=}"
		profile="${profile#\"}"
		profile="${profile%\"}"
		profile="${profile#\'}"
		profile="${profile%\'}"
	fi
	[ -n "$profile" ] || profile="personal"
	printf '%s\n' "$profile"
}

_task_env_write() {
	local profile="$1"
	_task_env_paths "$profile" || return 1
	printf '%s\n' "$profile" >"$TASK_PROFILE_FILE"
}

_task_env_exports() {
	local profile
	profile="$(_task_env_read)"
	_task_env_paths "$profile" || return 1
	printf 'export TASK_PROFILE=%q\n' "$profile"
	printf 'export TASKRC=%q\n' "$TASKRC"
	printf 'export TASKDATA=%q\n' "$TASKDATA"
}

_task_env_list() {
	printf '%s\n' personal work
}

_task_env_set() {
	local profile="$1"
	if [ -z "$profile" ]; then
		local prompt
		prompt="Taskwarrior profile ($(_task_env_read))"
		if [ -t 0 ]; then
			profile="$(_task_env_list | fzf --prompt "$prompt> ")"
		else
			profile="$(_task_env_list | rofi -dmenu -i -p "$prompt")"
		fi
	fi
	[ -n "$profile" ] || return 1
	_task_env_write "$profile" || return 1
	_task_env_paths "$profile"
	echo "TASK_PROFILE=$profile"
	echo "TASKRC=$TASKRC"
	echo "TASKDATA=$TASKDATA"
	if [ ! -t 0 ] && command -v notify-send >/dev/null 2>&1; then
		notify-send -i notes-panel "Taskwarrior" "Profile: $profile"
	fi
}

_task_env_real() {
	local name="$1"
	local selfdir p cand
	[ -n "$name" ] || {
		echo "task-env: usage: task-env real <command>" >&2
		return 2
	}
	selfdir="$(cd "$(dirname "$0")" && pwd)"
	local IFS=:
	for p in $PATH; do
		[ -n "$p" ] || continue
		cand="$p/$name"
		[ -x "$cand" ] || continue
		if [ "$(cd "$p" && pwd)" = "$selfdir" ]; then
			continue
		fi
		printf '%s\n' "$cand"
		return 0
	done
	echo "task-env: real '$name' not found on PATH" >&2
	return 127
}

_task_env_usage() {
	cat >&2 <<'EOF'
Usage: task-env [command]

  (none)|set [profile]  Pick/set active profile (fzf if tty, else rofi)
  <profile>             Set profile directly (personal|work)
  export|-e             Print shell exports for the active profile
  profile|get           Print active profile name
  list|ls               List known profiles
  real <command>        Resolve real binary, skipping wrapper dir
EOF
}

case "${1:-}" in
"" | set)
	_task_env_set "${2:-}"
	;;
export | -e)
	_task_env_exports
	;;
profile | get)
	_task_env_read
	;;
list | ls)
	_task_env_list
	;;
real)
	_task_env_real "${2:-}"
	;;
personal | work)
	_task_env_set "$1"
	;;
-h | --help | help)
	_task_env_usage
	;;
*)
	echo "task-env: unknown command '$1'" >&2
	_task_env_usage
	exit 2
	;;
esac
