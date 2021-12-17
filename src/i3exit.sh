#!/usr/bin/env sh
# /usr/bin/i3exit

# with openrc use loginctl
test $(cat /proc/1/comm) = "systemd" && logind=systemctl || logind=loginctl

_lock() { lock; }

case "$1" in
    lock)
		case $DESKTOP_SESSION in
			xfce) xfce4-screensaver-command -l ;;
			*) _lock ;;
		esac ;;
    logout)
		case $DESKTOP_SESSION in
			xfce) xfce4-session-logout -l ;;
			*) i3-msg exit ;;
		esac ;;
    switch_user)
		case $DESKTOP_SESSION in
			xfce) xfce4-session-logout -u ;;
			*) loginctl lock-session ;;
		esac ;;
    suspend)
        $logind suspend
        ;;
    hibernate)
        $logind hibernate
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
