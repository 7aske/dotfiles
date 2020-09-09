#!/usr/bin/env sh
# /usr/bin/i3exit

# with openrc use loginctl
test $(cat /proc/1/comm) = "systemd" && logind=systemctl || logind=loginctl

lockcommand="gnome-screensaver-command -l"

case "$1" in
    lock)
        $lockcommand
        ;;
    logout)
        i3-msg exit
        ;;
    switch_user)
        loginctl lock-session
        ;;
    suspend)
        $lockcommand && $logind suspend
        ;;
    hibernate)
        $lockcommand && $logind hibernate
        ;;
    reboot)
        $logind reboot
        ;;
    shutdown)
        $logind poweroff
        ;;
    *)
        echo "== ! i3exit: missing or invalid argument ! =="
        echo "Try again with: lock | logout | switch_user | suspend | hibernate | reboot | shutdown"
        exit 2
esac

exit 0
