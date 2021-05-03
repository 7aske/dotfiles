SERVICES=""
if [ "$(systemctl is-active docker)" = "active" ]; then
	SERVICES="$SERVICES "
fi

if [ "$(systemctl is-active mysqld)" = "active" ] \
	|| [ "$(systemctl is-active mariadb)" = "active" ] \
	|| [ "$(netstat -tln | grep -cE "(127.0.0.1|::1):3306")" -gt 0 ]; then
	SERVICES="$SERVICES  "
fi

if [ "$(systemctl is-active postgresql)" = "active" ] \
	|| [ "$(netstat -tln | grep -cE "(127.0.0.1|::1):5432")" -gt 0 ]; then
	SERVICES="$SERVICES  "
fi

if [ "$(systemctl is-active nginx)" = "active" ]; then
	SERVICES="$SERVICES  "
fi

if [ -z "$SERVICES" ]; then
	exit 0
fi

echo "<span>$SERVICES</span>"
