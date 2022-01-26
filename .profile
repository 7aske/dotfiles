# [ -f "$HOME/.profile" ] && . "$HOME/.profile"

export CODE="$HOME/.local/src"
export PROFILE_SOURCED=$USER

# Default programs
export EDITOR="nvim"
export BROWSER="brave"
export FILE="thunar"
export TERMFILE="ranger"
export READER="zathura"
export PLAYER="spotify"
export TERMINAL="st"
export TERMINAL_LAUNCH="$TERMINAL -e"
export MAIL="thunderbird"

# task
export TASKDATA="$HOME/.config/task"
export TASKRC="$HOME/.config/taskrc"

export FZF_CODE=1

# Path setup
prepend_path () {
	case ":$PATH:" in
		*:"$1":*)
			;;
		*)
			PATH="$1:${PATH:+$PATH}"
	esac
}

prepend_path "$HOME/.local/share/cargo/bin"
prepend_path "$HOME/Android/Sdk/emulator"
prepend_path "$HOME/.local/bin"
prepend_path "$HOME/.local/bin/scripts"

unset append_path

export PATH

export QT_QPA_PLATFORMTHEME="qt5ct"

# Thanks to Luke Smith https://github.com/LukeSmithxyz/voidrice
# ~/ Clean-up:
export ANSIBLE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ansible/ansible.cfg"
export CALCHISTFILE="${XDG_CACHE_HOME}/.calc_history"
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export GTK2_RC_FILES="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0/gtkrc-2.0"
export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/inputrc"
export KODI_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/kodi"
export LESSHISTFILE="-"
export MYSQL_HISTFILE="${XDG_CACHE_HOME}/.mysql_history"
export NODE_REPL_HISTORY="${XDG_CACHE_HOME}/.node_repl_history"
export NOTMUCH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/notmuch-config"
export NVIM_LOG_FILE="${XDG_CACHE_HOME}/.nvimlog"
export PASSWORD_STORE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/password-store"
export PSQL_HISTORY="${XDG_CACHE_HOME}/.psql_history"
export SQLITE_HISTORY="${XDG_CACHE_HOME}/.sqlite_history"
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export WGETRC="${XDG_CONFIG_HOME:-$HOME/.config}/wget/wgetrc"
export WINEPREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/wineprefixes/default"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
