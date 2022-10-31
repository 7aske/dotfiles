#!/usr/bin/env zsh

HISTFILE=~/.cache/zsh/history
ADOTDIR=~/.config/antigen

istty() {
	case $(tty) in 
		(/dev/tty[1-9]) return 0;; 
		(*) return 1;;
	esac
}

[ -e ~/.config/zsh/antigen.zsh ] && source ~/.config/zsh/antigen.zsh

antigen use oh-my-zsh
antigen bundle docker
antigen bundle docker-compose
antigen bundle kubectl
antigen bundle mvn
antigen bundle npm
antigen bundle pip
antigen bundle rust
antigen bundle command-not-found
antigen bundle virtualenv
antigen bundle gitignore
antigen bundle MichaelAquilina/zsh-you-should-use
if [ -x "$(command -v notify-send 2>/dev/null)" ]; then
	antigen bundle MichaelAquilina/zsh-auto-notify
fi
antigen bundle ael-code/zsh-colored-man-pages
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle fd

if [ ! $(istty) ]; then
	[ -e ~/.config/zsh/agnoster-custom.zsh-theme ] && source ~/.config/zsh/agnoster-custom.zsh-theme
else
	antigen theme risto
fi

antigen apply

export AUTO_NOTIFY_THRESHOLD=20

[ -e ~/.config/rc ] && source ~/.config/rc

#RPROMPT="%B%(?.%F{green}%?.%F{red}%?)%f%b"
#PROMPT="%B%{$fg[red]%}%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%1~%{$fg[red]%}%{$reset_color%} \$vcs_info_msg_0_%(!.#.λ)%b "

setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.

# Basic auto/tab complete:
setopt correct
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
setopt completealiases
_comp_options+=(globdots)		# Include hidden files.
COMPLETION_WAITING_DOTS="true"

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# change dir using FZF
bindkey -s '^f' 'cd "$(dirname "$(fzf)")"\n'

bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -s '^o' 'exec codeopen\n'
bindkey -s '^g' 'chgs\n'
bindkey -s '^v' 'vicfg\n'
bindkey -s '^p' 'git pull\n'
bindkey -s '^u' 'git push\n'
bindkey -s '^s' 'git status\n'
bindkey -s '^y' 'yay\n'

# ctrl+space
bindkey '^ ' autosuggest-accept
bindkey '^r' history-incremental-search-backward

# pidswallow
[ -n "$DISPLAY" ]  && command -v xdo >/dev/null 2>&1 && xdo id > /tmp/term-wid-"$$"
trap "( rm -f /tmp/term-wid-"$$" )" EXIT HUP

[ -e "$HOME/.zprofile" ] && . "$HOME/.zprofile"
