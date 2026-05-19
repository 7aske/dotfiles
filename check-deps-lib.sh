# Shared helpers for check-arch-deps.sh and check-apt-deps.sh.
# shellcheck shell=bash

declare -A IGNORE_PKGS=()
declare -a MISSING_ORDER=()

USE_DEPS_COLOR=false
C0='' CB='' C_REPO='' C_AUR='' C_PKG='' C_META='' C_CMD='' C_DIM=''

_deps_color_init() {
	USE_DEPS_COLOR=false
	if [ "${CHECK_DEPS_COLOR:-}" = "1" ]; then
		USE_DEPS_COLOR=true
	elif [ -t 1 ] && [ "${CHECK_DEPS_COLOR:-}" != "0" ] && [ -z "${NO_COLOR:-}" ]; then
		USE_DEPS_COLOR=true
	fi
	if $USE_DEPS_COLOR; then
		C0=$'\033[0m'
		CB=$'\033[1m'
		C_REPO=$'\033[1;35m' # pacman -Ss repo/
		C_AUR=$'\033[1;34m'  # yay aur/
		C_PKG=$'\033[1m'
		C_META=$'\033[1;36m' # [installed] [AUR]
		C_CMD=$'\033[36m'
		C_DIM=$'\033[2m'
	fi
}

_deps_print_heading() {
	if $USE_DEPS_COLOR; then
		printf '%b%s%b\n' "$CB" "$1" "$C0"
	else
		printf '%s\n' "$1"
	fi
}

_deps_print_summary() {
	local count="$1"
	if $USE_DEPS_COLOR; then
		printf '%b%d%b package(s) from this list are not installed.\n' "$CB" "$count" "$C0"
	else
		printf '%d package(s) from this list are not installed.\n' "$count"
	fi
}

_color_arch_pkg_spec() {
	local spec="$1"
	if ! $USE_DEPS_COLOR; then
		printf '%s' "$spec"
		return
	fi
	if [[ "$spec" == aur/* ]]; then
		printf '%saur%s/%s%s%s' "$C_AUR" "$C0" "$C_PKG" "${spec#aur/}" "$C0"
	elif [[ "$spec" == */* ]]; then
		printf '%s%s%s/%s%s%s' "$C_REPO" "${spec%%/*}" "$C0" "$C_PKG" "${spec#*/}" "$C0"
	else
		printf '%s%s%s' "$C_PKG" "$spec" "$C0"
	fi
}

_format_arch_dep_line() {
	local num="$1" spec="$2" cmd="$3" desc="$4" is_aur="$5" installed="$6"
	local pkg tag=''
	pkg="$(_color_arch_pkg_spec "$spec")"
	if [ "$is_aur" = 1 ] && [ "$installed" != 1 ]; then
		tag=$(printf ' %s[AUR]%s' "$C_META" "$C0")
	fi
	if [ "$installed" = 1 ]; then
		printf '    %b [%s%s%s]: %s %s[installed]%s' \
			"$pkg" "$C_CMD" "$cmd" "$C0" "$desc" "$C_META" "$C0"
		return
	fi
	printf '  %s%d)%s %b [%s%s%s]: %s%s' \
		"$C_DIM" "$num" "$C0" \
		"$pkg" "$C_CMD" "$cmd" "$C0" "$desc" "$tag"
}

_format_apt_dep_line() {
	local num="$1" pkg="$2" cmd="$3" desc="$4" installed="$5"
	if ! $USE_DEPS_COLOR; then
		if [ "$installed" = 1 ]; then
			printf '    %s [%s]: %s [installed]' "$pkg" "$cmd" "$desc"
		else
			printf '  %d) %s [%s]: %s' "$num" "$pkg" "$cmd" "$desc"
		fi
		return
	fi
	if [ "$installed" = 1 ]; then
		printf '    %s%s%s [%s%s%s]: %s %s[installed]%s' \
			"$C_PKG" "$pkg" "$C0" "$C_CMD" "$cmd" "$C0" "$desc" "$C_META" "$C0"
		return
	fi
	printf '  %s%d)%s %s%s%s [%s%s%s]: %s' \
		"$C_DIM" "$num" "$C0" "$C_PKG" "$pkg" "$C0" "$C_CMD" "$cmd" "$C0" "$desc"
}

_color_pkg_names() {
	local out=() pkg
	for pkg in "$@"; do
		if $USE_DEPS_COLOR; then
			out+=("${C_PKG}${pkg}${C0}")
		else
			out+=("$pkg")
		fi
	done
	# shellcheck disable=SC2145
	printf '%s' "${out[*]}"
}

_prompt_ignore_pkgs() {
	IGNORE_PKGS=()
	[ ${#MISSING_ORDER[@]} -eq 0 ] && return 0
	printf 'Items to skip (space-separated numbers, or leave empty): '
	read -r ignore_line || true
	local num pkg max=${#MISSING_ORDER[@]}
	for num in $ignore_line; do
		if ! [[ "$num" =~ ^[0-9]+$ ]]; then
			echo "check-deps: not a number: $num" >&2
			continue
		fi
		if [ "$num" -lt 1 ] || [ "$num" -gt "$max" ]; then
			echo "check-deps: number out of range (1-$max): $num" >&2
			continue
		fi
		pkg="${MISSING_ORDER[$((num - 1))]}"
		IGNORE_PKGS["$pkg"]=1
	done
}

_filter_ignored() {
	local -n arr=$1
	local filtered=() skipped=() pkg
	for pkg in "${arr[@]}"; do
		if [ -n "${IGNORE_PKGS[$pkg]:-}" ]; then
			skipped+=("$pkg")
			continue
		fi
		filtered+=("$pkg")
	done
	if [ ${#skipped[@]} -gt 0 ]; then
		printf 'Skipping: %b\n' "$(_color_pkg_names "${skipped[@]}")"
	fi
	arr=("${filtered[@]}")
}

_deps_color_init
