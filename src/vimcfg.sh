#!/usr/bin/env bash

[ -z "$EDITOR" ] &&  echo "$prog: EDITOR env variable not set" && exit 1

prog="$(basename "$0")"
find_flags="-maxdepth 1 -type f"
find_cmd="find"
_code_dotfiles="${CODE_DOTFILES:-$CODE/sh/dotfiles}"

floating="false"
cfg_dir=""
while getopts ":hHFecs" opt; do
    case $opt in
        e) cfg_dir="$cfg_dir /etc" ;;
        H) cfg_dir="$cfg_dir $HOME/" ;;
        c) cfg_dir="$cfg_dir $HOME/.config" ;;
        s) cfg_dir="$cfg_dir $HOME/.local/bin/scripts";;
        F) floating="true";;
        h) echo "Usage: $prog -[eHcsh]"; exit 0 ;;
        \?) echo "$prog: invalid option -- '$OPTARG'"; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

if [ -z "$cfg_dir" ]; then
    files="$(git -C "$_code_dotfiles" ls-files | xargs -I{} echo "$_code_dotfiles/{}")"
else
    files="$($find_cmd $cfg_dir $find_flags)"
fi

# Strip the longest common path prefix so the picker list is shorter and
# easier to fuzzy search; it's prepended again before the file is opened.
prefix=""
for f in $files; do
    if [ -z "$prefix" ]; then
        prefix="$f"
        continue
    fi
    while [ -n "$prefix" ] && [ "${f#"$prefix"}" = "$f" ]; do
        prefix="${prefix%?}"
    done
done
files="$(for f in $files; do printf '%s\n' "${f#"$prefix"}"; done)"


if [ ! -t 1 ]; then
	config_file="$(echo "$files" | sed 's/\ /\n/g' | grep -v ".git" | rofi -dmenu)"
else
	config_file="$(echo "$files" | sed 's/\ /\n/g' | grep -v ".git" | fzf --cycle --reverse --preview 'bat --style=numbers --color=always --line-range :100 '"$prefix"'{}' --preview-window=bottom:60%)"
fi

if [ -z "$config_file" ]; then
    exit 0
fi

config_file="$prefix$config_file"

git_root=""
if git -C "$(basename "$config_file")" rev-parse --is-inside-work-tree &>/dev/null; then
    git_root="$(git -C "$(basename "$config_file")" rev-parse --show-toplevel)"
fi

needs_sudo="false"
[ ! -w "$config_file" ] && needs_sudo="true"
elevate_cmd="sudo"
if [ "$needs_sudo" = "true" ] && [ ! -t 1 ] && command -v pkexec >/dev/null 2>&1; then
    elevate_cmd="pkexec"
fi

if [ -f "$config_file" ]; then
	if [ ! -t 1 ]; then
        # floating
        if [ "$floating" = "true" ]; then
            class="-c floating"
        fi

        if [ -n "$git_root" ]; then
            if [ "$needs_sudo" = "true" ]; then
                $TERMINAL "$class" -d "$git_root" -e "$elevate_cmd" "$EDITOR" "$config_file"
            else
                $TERMINAL "$class" -d "$git_root" -e "$EDITOR" "$config_file"
            fi
        else
            if [ "$needs_sudo" = "true" ]; then
                $TERMINAL "$class" -e "$elevate_cmd" "$EDITOR" "$config_file"
            else
                $TERMINAL "$class" -e "$EDITOR" "$config_file"
            fi
        fi
	else
        if [ -n "$git_root" ]; then
            cd "$git_root" || exit 1
            if [ "$needs_sudo" = "true" ]; then
                sudo "$EDITOR" "$config_file"
            else
                "$EDITOR" "$config_file"
            fi
        else 
            if [ "$needs_sudo" = "true" ]; then
                sudo "$EDITOR" "$config_file"
            else
                "$EDITOR" "$config_file"
            fi
        fi
	fi
elif [ -n "$config_file" ]; then
    echo "$prog: $config_file: no such file or directory" && exit 1
fi
