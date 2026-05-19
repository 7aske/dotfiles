#!/usr/bin/env bash
# Notify when new package updates appear (compare against last run).
#
# Cron example (hourly, only notifies when count increases):
#   0 * * * * /home/USER/.local/bin/yup-notify
#
# Ensure yup has a fresh list first, e.g. refresh /tmp/yup via:
#   0 * * * * yay -Qu > /tmp/yup 2>/dev/null; /home/USER/.local/bin/yup-notify
# or run `yup -r` in the same cron line before this script.

tempfile="/tmp/yup_prev"
count="$(yup -c)"
prev_count="$(cat "$tempfile" 2>/dev/null || echo 0)"

if [ "$prev_count" -lt "$count" ]; then
    notify-send -i package -u low "updates available" "$(yup -l)"
fi

echo "$count" > "$tempfile"
