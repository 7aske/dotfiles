#!/usr/bin/env bash

LOCALSEND_FILE="/tmp/localsend"
LCKFILE="/tmp/${0##*/}.lck"
PIDFILE="/tmp/${0##*/}.pid"

_usage() {
    echo "Usage: ${0##*/} [-kh]"
    echo "  -h    Show this help message"
    echo "  -k    Kill existing instance of this script"
    exit 0
}

_kill_existing_instance() {
    if [ -f "$PIDFILE" ]; then
        echo "Killing existing instance with PID $(cat "$PIDFILE")"
        kill -TERM -- -"$(cat "$PIDFILE")"
    fi
    exit 0
}

while getopts "kh" opt; do
    case $opt in
        h) _usage ;;
        k) _kill_existing_instance ;;
        *) _usage ;;
    esac
done

if [ -z "$(pgrep -f "localsend")" ]; then
    echo "LocalSend is not running. Exiting."
    exit 1
fi

umask 000                   # allow all users to access the file we're about to create
exec 9>"$LCKFILE"           # open lockfile on FD 9, based on basename of argv[0]
umask 022                   # move back to more restrictive file permissions
flock -x -n 9 || exit       # grab that lock, or exit the script early
echo $$ > "$PIDFILE"        # record our PID to a file
trap 'rm -f "$PIDFILE"' EXIT

while ! [ -e "$LOCALSEND_FILE" ]; do
    echo "LocalSend log file not found at $LOCALSEND_FILE. Sleeping."
    sleep 10
done

notify-send -u normal -i localsend_app "LocalSend" "Monitoring for incoming files"

while IFS= read -r line; do
    if [[ "$line" =~ Destination\ Directory:.* ]]; then
        localsend_dest_dir="$(echo "$line" | awk '
        $0 ~ /.*Destination Directory:.*/ {
            split($0, a, "Destination Directory: ")
            print a[2]
            exit
        }')"
        echo "Set destination directory to: $localsend_dest_dir"
    fi

    if [[ "$line" =~ Saved\ .* ]] && [ -n "$localsend_dest_dir" ]; then
        file_name="$(echo "$line" | awk '
        {
            split($0, a, "Saved ")
            print substr(a[2], 1, length(a[2])-1)
        }')"
        echo "Received file: $file_name"

        action="$(notify-send -u normal -i localsend_app "LocalSend" "Received file: $file_name" -A "folder=Open folder($localsend_dest_dir)" -A "file=Open file($file_name)")"
        if [[ "$action" == "folder" ]]; then
            echo "Opening folder: $localsend_dest_dir"
            xdg-open "$localsend_dest_dir" >/dev/null 2>&1
        elif [[ "$action" == "file" ]]; then
            echo "Opening file: $localsend_dest_dir/$file_name"
            xdg-open "$localsend_dest_dir/$file_name" > /dev/null 2>&1
        fi
    fi
done < <(tail -n0 -F "$LOCALSEND_FILE")
