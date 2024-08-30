#!/usr/bin/env sh

# toggles ideapad battery conservation mode

setting=/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
state=$(cat $setting)

case $1 in 
	on|1)  state=1 ;;
	off|0) state=0 ;;
	*)     state=$((1 - "$state")) ;;
esac


echo $state | sudo tee "$setting"
