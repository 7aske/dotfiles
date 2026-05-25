#!/usr/bin/env bash
# Dispatch to the OS-appropriate dependency checker (see /etc/os-release).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS="$ROOT/.deps"

_pick_script() {
	local id="${ID:-}" id_like="${ID_LIKE:-}"

	case "$id" in
		arch|endeavouros|manjaro|garuda|cachyos)
			echo "$DEPS/check-arch-deps.sh"
			return
			;;
		ubuntu|debian|pop|linuxmint|elementary|zorin|kubuntu|xubuntu|lubuntu)
			echo "$DEPS/check-apt-deps.sh"
			return
			;;
	esac

	case "$id_like" in
		*arch*) echo "$DEPS/check-arch-deps.sh" ;;
		*debian*|*ubuntu*) echo "$DEPS/check-apt-deps.sh" ;;
		*) echo "$DEPS/check-arch-deps.sh" ;;
	esac
}

if [ -r /etc/os-release ]; then
	# shellcheck disable=SC1091
	. /etc/os-release
fi

script="$(_pick_script)"
exec "$script" "$@"
