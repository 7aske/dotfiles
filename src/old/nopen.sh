#!/usr/bin/env sh

_usage(){
	>&2 echo "usage: $0 <type>"
	>&2 echo "types:"
	>&2 echo "   terminal"
	>&2 echo "   reader"
	>&2 echo "   browser"
	>&2 echo "   termfile"
	>&2 echo "   file"
	>&2 echo "   editor"
	>&2 echo "   visual"
}

_exec_env(){
	VAR="$(echo $1 | tr [:lower:] [:upper:])"
	setsid gtk-launch "$(printenv $VAR)" 2>/dev/null 1>/dev/null
}

_exec_env $1
