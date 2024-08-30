#!/usr/bin/env bash

if ! ( systemctl is-active acpid );then
    echo "acpid is not running"
    exit 0
fi

umask 000                  # allow all users to access the file we're about to create
exec 9>"/tmp/${0##*/}.lck" # open lockfile on FD 9, based on basename of argv[0]
umask 022                  # move back to more restrictive file permissions
flock -x -n 9 || exit 0    # grab that lock, or exit the script early

acpi_listen | while IFS= read -r line; do
    if [[ "$line" =~ ^ac_adapter.*$ ]]; then
        status="Battery charging"
        if [[ "$line" =~ ^.*0$ ]];then
            status="Battery discharging"
        fi
        sleep 0.5
        pkill -SIGRTMIN+9 i3blocks
        notify-send -a battery -i battery 'Battery' "$status"
    fi
done
