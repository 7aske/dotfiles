# Shared desktop notification environment for agent hooks.
# Agents spawn hooks without a graphical session; bootstrap one here.

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

if [ -z "${DISPLAY:-}" ] && compgen -G '/tmp/.X11-unix/X*' >/dev/null; then
  disp=$(compgen -G '/tmp/.X11-unix/X*' | head -1)
  export DISPLAY=":${disp##*X}"
fi

export DISPLAY="${DISPLAY:-:0}"

# shellcheck disable=SC1091
{
  [ -z "${DOTS_COLORS_SOURCED:-}" ] && [ -f "$HOME/.config/colors.sh" ] && . "$HOME/.config/colors.sh"
}

# Nord fallbacks if colors.sh is missing
: "${white:=#D8DEE9}"
: "${red:=#BF616A}"
: "${orange:=#D08770}"
: "${yellow:=#EBCB8B}"
: "${green:=#A3BE8C}"
: "${blue:=#5E81AC}"
: "${magenta:=#B48EAD}"
: "${color3:=#EBCB8B}"
: "${color8:=#4C566A}"

pango_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

pango_span() {
  # pango_span <color> <text>
  printf '<span foreground="%s">%s</span>' "$1" "$(pango_escape "$2")"
}
