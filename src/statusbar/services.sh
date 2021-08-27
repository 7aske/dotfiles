declare -A SERVICES
if [ "$(systemctl is-active docker)" = "active" ]; then
	SERVICES+=(["docker"]="")
fi

if [ "$(systemctl is-active mysqld)" = "active" ] \
	|| [ "$(systemctl is-active mariadb)" = "active" ] \
	|| [ "$(netstat -tln | grep -cE "(127.0.0.1|::1):3306")" -gt 0 ]; then
	SERVICES+=(["mysql"]="")
fi

if [ "$(systemctl is-active postgresql)" = "active" ] \
	|| [ "$(netstat -tln | grep -cE "(127.0.0.1|::1):5432")" -gt 0 ]; then
	SERVICES+=(["postres"]="")
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

echo "<span>$(for serv in ${SERVICES[@]}; do echo -n "$serv "; done)</span>"

