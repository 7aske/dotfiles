#!/usr/bin/env bash

NETSTAT="$(netstat -tlpn)"

declare -A SERVICES
if [ "$(systemctl is-active docker)" = "active" ]; then
	SERVICES+=(["docker"]="")
fi

if [ "$(systemctl is-active mysqld)" = "active" ] \
	|| [ "$(systemctl is-active mariadb)" = "active" ] \
	|| [ "$(echo "$NETSTAT" | grep -cE "([0-9]+.[0-9]+.[0-9]+.[0-9]+|::[1:]?):3306\b")" -gt 0 ]; then
	SERVICES+=(["mysql"]="")
fi

if [ "$(systemctl is-active mongodb)" = "active" ] \
	|| [ "$(echo "$NETSTAT" | grep -cE "([0-9]+.[0-9]+.[0-9]+.[0-9]+|::[1:]?):27017\b")" -gt 0 ]; then
	SERVICES+=(["mongodb"]="")
fi

if [ "$(systemctl is-active postgresql)" = "active" ] \
	|| [ "$(echo "$NETSTAT" | grep -cE "([0-9]+.[0-9]+.[0-9]+.[0-9]+|::[1:]?):5432\b")" -gt 0 ]; then
	SERVICES+=(["postres"]="")
fi

if [ "$(systemctl is-active redis)" = "active" ] \
	|| [ "$(echo "$NETSTAT" | grep -cE "([0-9]+.[0-9]+.[0-9]+.[0-9]+|::[1:]?):6379\b")" -gt 0 ]; then
	SERVICES+=(["redis"]="")
fi

if [ "$(echo "$NETSTAT" | grep -cE "([0-9]+.[0-9]+.[0-9]+.[0-9]+|::[1:]?):8080.*java\b")" -gt 0 ]; then
	SERVICES+=(["java"]="")
fi

if [ "$(echo "$NETSTAT" | grep -cE "([0-9]+.[0-9]+.[0-9]+.[0-9]+|::[1:]?):8080.*node\b")" -gt 0 ]; then
	SERVICES+=(["node"]="")
fi

if [ "$(echo "$NETSTAT" | grep -cE "([0-9]+.[0-9]+.[0-9]+.[0-9]+|::[1:]?):4200.*node\b")" -gt 0 ]; then
	SERVICES+=(["angular"]="")
fi

if [ "$(systemctl is-active nginx)" = "active" ]; then
	SERVICES+=(["nginx"]="")
fi

if [ "${#SERVICES[@]}" -eq 0 ]; then
	exit 0
fi

case $BLOCK_BUTTON in
	1) notify-send -a services "active services" "$(for serv in ${!SERVICES[@]}; do echo "$serv"; done)" ;;
esac

echo "<span size='x-large'> $(for serv in ${SERVICES[@]}; do echo -n "$serv "; done)</span>"

