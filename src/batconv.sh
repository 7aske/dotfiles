#!/usr/bin/env sh

# toggles ideapad battery conservation mode

setting=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
state=$(cat $setting)

case $1 in 
	on|1)  state=1 ;;
	off|0) state=0 ;;
	*)     state=$((1 - "$state")) ;;
esac

elevate_command=""
if [ -t 0 ]; then
	elevate_command="sudo"
else
	elevate_command="pkexec"
fi

echo $state | $elevate_command tee "$setting"

notify-send -u low -t 2000 -i battery-full-charged-symbolic "Battery conservation mode" "Battery conservation mode is now $(if [ "$state" -eq 1 ]; then echo "enabled"; else echo "disabled"; fi)."

pkill -SIGRTMIN+9 i3status-rs 
