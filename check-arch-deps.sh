#!/usr/bin/env bash
# Report (and optionally install) Arch packages required by dotfiles scripts.
# Project-provided commands under src/ are never suggested for installation.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="${ARCH_DEPS_CONF:-$ROOT/arch-deps.conf}"
INSTALL=false
QUIET=false
NONINTERACTIVE=false
LIST_INSTALLED=false

usage() {
	cat <<'EOF'
Usage: check-arch-deps.sh [options]

Report optional Arch dependencies for dotfiles scripts (pacman-style).

Options:
  -i, --install          Install missing repo packages (AUR via yay when available)
  -n, --non-interactive  Do not prompt to install (for make install, git hooks)
      --list-installed   Include already-installed packages in the report
  -q, --quiet            Only print output when something is missing
  -h, --help             Show this help

Environment:
  CHECK_DEPS=0        Skip when set (also honors CHECK_ARCH_DEPS=0)
  ARCH_DEPS_CONF      Alternate manifest path
  ARCH_DEPS_GUI=1|0   Force GUI/headless detection (auto-detected by default)
EOF
}

_has_gui() {
	case "${ARCH_DEPS_GUI:-}" in
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
		for dm in display-manager gdm sddm lightdm lxdm; do
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
		*) echo "check-arch-deps.sh: unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
	shift
done

if [ "${CHECK_DEPS:-${CHECK_ARCH_DEPS:-1}}" = "0" ]; then
	exit 0
fi

if [ ! -f "$CONF" ]; then
	echo "check-arch-deps.sh: manifest not found: $CONF" >&2
	exit 1
fi

# Commands provided by this repo. Wrappers that exec /bin/<name> are not excluded
# (e.g. dmenu.sh still needs the dmenu package).
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
	pacman -Q "$pkg" >/dev/null 2>&1
}

_parse_pkg() {
	local spec="$1"
	PKG_REPO=true
	PKG_NAME="$spec"
	if [[ "$spec" == aur/* ]]; then
		PKG_REPO=false
		PKG_NAME="${spec#aur/}"
	elif [[ "$spec" == */* ]]; then
		PKG_NAME="${spec#*/}"
	fi
}

HAS_GUI=false
_has_gui && HAS_GUI=true

declare -a MISSING_REPO=()
declare -a MISSING_AUR=()
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

	# One line per package (first command wins for install list).
	duplicate=false
	for s in "${seen_pkg[@]}"; do
		[ "$s" = "$pkg" ] && duplicate=true && break
	done
	$duplicate && continue
	seen_pkg+=("$pkg")

	_parse_pkg "$pkg"
	installed=false
	if _dep_installed "$PKG_NAME" "$cmd"; then
		installed=true
	fi

	if $installed; then
		$LIST_INSTALLED || continue
		status=" [installed]"
	else
		if $PKG_REPO; then
			MISSING_REPO+=("$PKG_NAME")
		else
			MISSING_AUR+=("$PKG_NAME")
		fi
		status=""
	fi

	repo_tag=""
	$PKG_REPO || repo_tag=" [AUR]"
	LINES+=("    ${pkg} [${cmd}]: ${desc}${repo_tag}${status}")
done <"$CONF"

missing_count=$((${#MISSING_REPO[@]} + ${#MISSING_AUR[@]}))

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

_install_repo() {
	[ ${#MISSING_REPO[@]} -eq 0 ] && return 0
	echo "Installing: ${MISSING_REPO[*]}"
	if [ -n "${DRYRUN:-}" ] && [ "$DRYRUN" != "0" ]; then
		echo "  (dry-run) sudo pacman -S --needed --noconfirm ${MISSING_REPO[*]}"
		return 0
	fi
	sudo pacman -S --needed --noconfirm "${MISSING_REPO[@]}"
}

_install_aur() {
	[ ${#MISSING_AUR[@]} -eq 0 ] && return 0
	if ! command -v yay >/dev/null 2>&1; then
		echo "AUR packages not installed (install yay to use --install): ${MISSING_AUR[*]}" >&2
		return 1
	fi
	echo "Installing (AUR): ${MISSING_AUR[*]}"
	if [ -n "${DRYRUN:-}" ] && [ "$DRYRUN" != "0" ]; then
		echo "  (dry-run) yay -S --needed --noconfirm ${MISSING_AUR[*]}"
		return 0
	fi
	yay -S --needed --noconfirm "${MISSING_AUR[@]}"
}

if $INSTALL; then
	_install_repo
	_install_aur
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
		_install_repo
		_install_aur
		;;
	*)
		echo "Skipped. Install later with: make install-deps"
		;;
esac
