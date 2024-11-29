#!/usr/bin/env bash

netstat -tlpn 2>/dev/null \
	| grep LISTEN \
	| awk '
	{
		fmt = "%-16s %-7s %s\n"
		if (NR == 1) {
			printf fmt, "PORT", "PID", "PROCESS"

		}
        if ($7 == "-") {
            next
        }
		split($7, proc, "/");
		printf fmt, $4, proc[1], proc[2]
	}' \
	| dmenu -l 10 -p kill \
	| awk '{print $2}' \
	| xargs kill
