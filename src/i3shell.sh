#!/usr/bin/env bash

I3SHELL_HISTFILE="${I3SHELL_HISTFILE:-"$HOME/.cache/i3shell"}"
I3SHELL_HISTSIZE="${I3SHELL_HISTSIZE:-"1000"}"

COMMAND="$(cat "$I3SHELL_HISTFILE" | sort | uniq | dmenu -b -p ':' -l 3)"

if [ -z "$COMMAND" ]; then
	exit 1
fi

i3-msg $COMMAND && notify-send -a i3shell i3shell "$COMMAND" || exit 1

echo "$COMMAND" >> "$I3SHELL_HISTFILE"
echo "$(tail -"$I3SHELL_HISTSIZE" "$I3SHELL_HISTFILE")" > "$I3SHELL_HISTFILE"
