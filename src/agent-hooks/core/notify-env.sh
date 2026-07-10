# Shared desktop notification environment for agent hooks.
# Agents spawn hooks without a graphical session; bootstrap one here.

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

if [ -z "${DISPLAY:-}" ] && compgen -G '/tmp/.X11-unix/X*' >/dev/null; then
  disp=$(compgen -G '/tmp/.X11-unix/X*' | head -1)
  export DISPLAY=":${disp##*X}"
fi

export DISPLAY="${DISPLAY:-:0}"
