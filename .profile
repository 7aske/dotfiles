# [ -f "$HOME/.profile" ] && . "$HOME/.profile"

export CODE="$HOME/.local/src"
export PROFILE_SOURCED=$USER

# Default programs
export EDITOR="nvim"
export BROWSER="brave"
export FILE="nautilus"
export TERMFILE="ranger"
export READER="zathura"
export PLAYER="spotify"
export TERMINAL="st"
export MAIL="evolution"

# task
export TASKDATA="$HOME/.config/task"
export TASKRC="$HOME/.config/taskrc"

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

unset append_path

export PATH

export QT_QPA_PLATFORMTHEME="qt5ct"

# Thanks to Luke Smith https://github.com/LukeSmithxyz/voidrice
# ~/ Clean-up:
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export NOTMUCH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/notmuch-config"
export GTK2_RC_FILES="${XDG_CONFIG_HOME:-$HOME/.config}/gtk-2.0/gtkrc-2.0"
export LESSHISTFILE="-"
export WGETRC="${XDG_CONFIG_HOME:-$HOME/.config}/wget/wgetrc"
export INPUTRC="${XDG_CONFIG_HOME:-$HOME/.config}/inputrc"
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
export WINEPREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/wineprefixes/default"
export KODI_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/kodi"
export PASSWORD_STORE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/password-store"
export TMUX_TMPDIR="$XDG_RUNTIME_DIR"
export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
export GOPATH="${XDG_DATA_HOME:-$HOME/.local/share}/go"
export ANSIBLE_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ansible/ansible.cfg"
export NODE_REPL_HISTORY="${XDG_CACHE_HOME}/.node_repl_history"
export PSQL_HISTORY="${XDG_CACHE_HOME}/.psql_history"
export MYSQL_HISTFILE="${XDG_CACHE_HOME}/.mysql_history"
