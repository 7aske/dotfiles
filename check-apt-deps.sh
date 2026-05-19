#!/usr/bin/env bash
# Report (and optionally install) Debian/Ubuntu packages required by dotfiles scripts.
# Project-provided commands under src/ are never suggested for installation.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${APT_DEPS_CONF:-$ROOT/apt-deps.conf}"
INSTALL=false
QUIET=false
NONINTERACTIVE=false
LIST_INSTALLED=false

usage() {
	cat <<'EOF'
Usage: check-apt-deps.sh [options]

Report optional apt dependencies for dotfiles scripts (apt-style).

Options:
  -i, --install          Install missing packages (sudo apt-get install)
  -n, --non-interactive  Do not prompt to install (for make install, git hooks)
      --list-installed   Include already-installed packages in the report
  -q, --quiet            Only print output when something is missing
  -h, --help             Show this help

Environment:
  CHECK_DEPS=0        Skip when set (also honors CHECK_APT_DEPS=0)
  APT_DEPS_CONF       Alternate manifest path
  APT_DEPS_GUI=1|0    Force GUI/headless detection (auto-detected by default)
EOF
}

_has_gui() {
	case "${APT_DEPS_GUI:-${ARCH_DEPS_GUI:-}}" in
		1|true|yes) return 0 ;;
		0|false|no) return 1 ;;
	esac

	[ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] && return 0
	case "${XDG_SESSION_TYPE:-}" in
		x11|wayland|mir) return 0 ;;
	esac

	if command -v loginctl >/dev/null 2>&1; then
		local sid type
		while read -r sid _; do
			[ -n "$sid" ] || continue
			type="$(loginctl show-session "$sid" -p Type --value 2>/dev/null || true)"
			case "$type" in
				x11|wayland) return 0 ;;
			esac
		done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
	fi

	if command -v systemctl >/dev/null 2>&1; then
		[ "$(systemctl get-default 2>/dev/null)" = "graphical.target" ] && return 0
		local dm
		for dm in display-manager gdm3 sddm lightdm lxdm; do
			systemctl is-active --quiet "$dm" 2>/dev/null && return 0
		done
	fi

	return 1
}

while [ $# -gt 0 ]; do
	case "$1" in
		-i|--install) INSTALL=true ;;
		-n|--non-interactive) NONINTERACTIVE=true ;;
		--list-installed) LIST_INSTALLED=true ;;
		-q|--quiet) QUIET=true ;;
		-h|--help) usage; exit 0 ;;
		*) echo "check-apt-deps.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
	shift
done

if [ "${CHECK_DEPS:-${CHECK_APT_DEPS:-1}}" = "0" ]; then
	exit 0
fi

if [ ! -f "$CONF" ]; then
	echo "check-apt-deps.sh: manifest not found: $CONF" >&2
	exit 1
fi

if ! command -v dpkg >/dev/null 2>&1; then
	echo "check-apt-deps.sh: dpkg not found (not a Debian/Ubuntu system?)" >&2
	exit 1
fi

declare -A LOCAL_CMDS=()
while IFS= read -r path; do
	name="$(basename "$path")"
	name="${name%.*}"
	if grep -qE "exec[[:space:]]+/(usr/)?bin/${name}([[:space:]]|$)" "$path" 2>/dev/null; then
		continue
	fi
	LOCAL_CMDS["$name"]=1
done < <(find "$ROOT/src" \( -name '*.sh' -o -name '*.py' \) ! -path '*/old/*' -print | sort)

_dep_installed() {
	local pkg="$1" cmd="$2"
	if command -v "$cmd" >/dev/null 2>&1; then
		return 0
	fi
	dpkg -s "$pkg" >/dev/null 2>&1
}

HAS_GUI=false
_has_gui && HAS_GUI=true

declare -a MISSING_PKGS=()
declare -a LINES=()
seen_pkg=()

while IFS= read -r line || [ -n "$line" ]; do
	line="${line%%#*}"
	line="${line#"${line%%[![:space:]]*}"}"
	line="${line%"${line##*[![:space:]]}"}"
	[ -z "$line" ] && continue

	IFS='|' read -r pkg cmd desc tags <<<"$line"
	[ -z "$pkg" ] || [ -z "$cmd" ] && continue
	[ -n "${LOCAL_CMDS[$cmd]:-}" ] && continue
	if ! $HAS_GUI && [ "${tags:-}" = "gui" ]; then
		continue
	fi

	duplicate=false
	for s in "${seen_pkg[@]}"; do
		[ "$s" = "$pkg" ] && duplicate=true && break
	done
	$duplicate && continue
	seen_pkg+=("$pkg")

	installed=false
	if _dep_installed "$pkg" "$cmd"; then
		installed=true
	fi

	if $installed; then
		$LIST_INSTALLED || continue
		status=" [installed]"
	else
		MISSING_PKGS+=("$pkg")
		status=""
	fi

	LINES+=("    ${pkg} [${cmd}]: ${desc}${status}")
done <"$CONF"

missing_count=${#MISSING_PKGS[@]}

if $QUIET && [ "$missing_count" -eq 0 ]; then
	exit 0
fi

if [ "$missing_count" -eq 0 ]; then
	echo "All listed dependencies are satisfied."
	exit 0
fi

echo "Optional dependencies for dotfiles:"
printf '%s\n' "${LINES[@]}"

echo
echo "$missing_count package(s) from this list are not installed."
if ! $HAS_GUI; then
	echo "(GUI-only dependencies omitted on this headless host.)"
fi

_install_pkgs() {
	[ ${#MISSING_PKGS[@]} -eq 0 ] && return 0
	echo "Installing: ${MISSING_PKGS[*]}"
	if [ -n "${DRYRUN:-}" ] && [ "$DRYRUN" != "0" ]; then
		echo "  (dry-run) sudo apt-get install -y ${MISSING_PKGS[*]}"
		return 0
	fi
	sudo apt-get update
	sudo apt-get install -y "${MISSING_PKGS[@]}"
}

if $INSTALL; then
	_install_pkgs
	exit 0
fi

if $NONINTERACTIVE || [ ! -t 0 ]; then
	echo "Run 'make install-deps' or './check-deps.sh --install' to install missing packages."
	exit 0
fi

printf 'Install missing packages? [y/N] '
read -r reply
case "$reply" in
	[yY]|[yY][eE][sS])
		INSTALL=true
		_install_pkgs
		;;
	*)
		echo "Skipped. Install later with: make install-deps"
		;;
esac
