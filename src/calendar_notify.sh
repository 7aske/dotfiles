#!/usr/bin/env sh

currenttime=$(date +%s)

# borrowed from https://github.com/sahasatvik/dotfiles

# Run as a timed systemd --user service.

seconds_before_critical=$(( 60 * 60 ))
seconds_before_normal=$(( 60 * 60 * 3 ))
CALENDARFILE="${CALENDARFILE:-"$HOME/.config/calendar"}"
logfile="$HOME/.config/.calendarlog"

touch "$logfile"
log="$(cat $logfile)"

IFS=,
cat "$CALENDARFILE" | \
sed 's/^\s*#.*$//g' | sed '/^$/d' | sed 's/\s*,\s*/,/g' | \
while read line; do
        read etime title description <<< $line
        eventtime="$(date --date=$etime +%s)"

        #[ ! -z $(echo "$log" | grep "$eventtime $title") ] && continue
        [ $eventtime -lt $currenttime ] && continue

        diff=$(($eventtime-$currenttime))
		echo $diff $seconds_before_normal
        [ $diff -gt $seconds_before_normal ] && continue

        hhmm="$(date --date=$etime +%H:%M)"

		level="normal"
		if [ $diff -lt "$seconds_before_critical" ]; then
			level="critical"
		fi

        notify-send -u "$level" \
                "$title at $hhmm" "$description\n" \
                -h string:x-canonical-private-synchronous:"$hhmm $title" && \
        echo "$eventtime $title" >> $logfile
done
