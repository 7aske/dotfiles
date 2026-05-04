#!/usr/bin/env bash

lid_ac="xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-ac"
lid_bat="xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/lid-action-on-battery"
pres_mode="xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/presentation-mode"

if [ $# -eq 0 ]; then
	curr="$(eval "$lid_ac")"
	((curr ^= 1))
	eval "$lid_ac -s $curr"
	notify-send "lid ac" "lid ac set to $curr" || echo"lid ac set to $curr" 
	curr="$(eval "$lid_bat")"
	((curr ^= 1))

	eval "$lid_bat -s $curr"
	notify-send "lid bat" "lid bat set to $curr" || echo "lid bat set to $curr" 
	curr="$(eval "$pres_mode")"

	if [ "$curr" == "true" ]; then
		eval "$pres_mode -s false"
		notify-send "presentation mode" "presentation mode disabled" || echo "presentation mode disabled" 
	else
		eval "$pres_mode -s true"
		notify-send "presentation mode" "presentation mode enabled" || echo "presentation mode enabled" 
	fi
fi
