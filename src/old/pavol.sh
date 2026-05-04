#!/usr/bin/env sh

PROG="$(basename $0)"

prog_name="$1"
volume="$2"

sink_inputs="$(pactl list sink-inputs | grep  -e "Sink Input" -e "application.name = " -e "appication.process.id" -e "application.process.binary" | sed -n "s/^Sink\ Input\ \#//p;s/.*\"\(.*\)\"/\1/p" | awk '{ printf "%s", $0; if (NR % 3 == 0) print ""; else if (NR % 3 == 1) printf "\t"; else printf "\t" }')"

if [ -z "$prog_name" ] || [ -z "$volume" ]; then
	echo -e "$sink_inputs"
	exit 0
fi

SEP=$IFS
IFS=$'\n'
for prog in $sink_inputs; do
	sink_data="$(echo $prog | grep -i $prog_name)"
	sink_id="$(echo "$sink_data" | awk -F '\t' '{print $1}')"
	sink_name="$(echo "$sink_data" | awk -F '\t' '{print $2}')"
	if [ -n "$sink_id" ]; then
		echo "$PROG: setting '$sink_name' ($sink_id) volume to $2"
		pactl set-sink-input-volume $sink_id "$volume"
	fi
done
IFS=$SEP
