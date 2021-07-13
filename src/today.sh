#!/usr/bin/env sh

[ -e "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"

currenttime="$(date +%s)"
todaydate="$(date +%D)"

# borrowed from https://github.com/sahasatvik/dotfiles

CALENDARFILE="${CALENDARFILE:-"$HOME/.config/calendar"}" # calendar event file

format_entries() {
        IFS=,
        cat "$CALENDARFILE" | \
        sed 's/^\s*#.*$//g' | sed '/^$/d' | sed 's/\s*,\s*/,/g' | \
        while read line; do
                read etime title description <<< $line
                eventdate="$(date --date=$etime +%D)"

                [ "$eventdate" != "$todaydate" ] && continue

                eventtime="$(date --date=$etime +%s)"
                hhmm="$(date --date=$etime +%H:%M)"

                if [ $eventtime -lt $currenttime ]; then
                        echo "$hhmm,$title,$description" | \
						awk -F',' '{printf "<span color=\"'$color8'\">%6s  %-16s  %-46s</span>\n", $1, $2, $3}'
                else
                        echo "$hhmm,$title,$description" | \
                        awk -F',' '{printf "%6s  %-16s  <span color=\"'$color7'\">%-46s</span>\n", $1, $2, $3}'
                fi
        done
}

format_entries \
		| sort \
		| rofi -dmenu -markup-rows -i -p 'today'
