#!/usr/bin/env zsh

HISTFILE=~/.cache/zsh/history
ADOTDIR=~/.config/antigen
AWS_REGION_FILE="$HOME/.aws_region"
AWS_PROFILE_FILE="$HOME/.aws_profile"
AWS_CONFIG_FILE="$HOME/.aws/config"

istty() {
	case $(tty) in 
		(/dev/tty[1-9]) return 0;; 
		(*) return 1;;
	esac
}

[ -e "$AWS_PROFILE_FILE" ] && source "$AWS_PROFILE_FILE"
[ -e "$AWS_REGION_FILE" ] && source "$AWS_REGION_FILE"

[ -e ~/.config/zsh/antigen.zsh ] && source ~/.config/zsh/antigen.zsh

antigen use oh-my-zsh
antigen bundle ael-code/zsh-colored-man-pages
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

antigen bundle argocd
antigen bundle aws
antigen bundle colored-man-pages
antigen bundle command-not-found
antigen bundle direnv
antigen bundle docker
antigen bundle docker-compose
antigen bundle emoji
antigen bundle fd
antigen bundle gitignore
antigen bundle gradle
antigen bundle helm
antigen bundle history-substring-search
antigen bundle kubectl
antigen bundle kubectx
antigen bundle minikube
antigen bundle mvn
antigen bundle npm
antigen bundle pip
antigen bundle rust
antigen bundle virtualenv
antigen bundle emoji
antigen bundle MichaelAquilina/zsh-you-should-use
if [ -x "$(command -v notify-send 2>/dev/null)" ]; then
	antigen bundle MichaelAquilina/zsh-auto-notify
fi

if ! (( $(istty) )); then
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
autoload -Uz compinit bashcompinit
compinit && bashcompinit
fpath+=~/.zfunc
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" menu select
zmodload zsh/complist
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
bindkey -s '^f' 'cd "$(dirname "$(fzf --bind "ctrl-e:execute(vim {})" --preview  "bat --color=always {}" --preview-window "up,60%,border-bottom,+{2}+3/3,~3")")"\n'

bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -s '^o' 'codeopen\n'
bindkey -s '^g' 'chgs\n'
bindkey -s '^v' 'vicfg -H -c -s\n'
bindkey -s '^p' 'git pull\n'
bindkey -s '^u' 'git push\n'
bindkey -s '^s' 'git status\n'
bindkey -s '^y' 'yay\n'

# ctrl+space
bindkey '^ ' autosuggest-accept
bindkey '^r' history-incremental-search-backward

alias dockerhost="export DOCKER_HOST=\$(docker context inspect \$(docker context show) | jq -r '.[0].Endpoints.docker.Host')"

# pidswallow
[ -n "$DISPLAY" ]  && command -v xdo >/dev/null 2>&1 && xdo id > /tmp/term-wid-"$$"
trap "( rm -f /tmp/term-wid-"$$" )" EXIT HUP

[ -e "$HOME/.zprofile" ] && source "$HOME/.zprofile"

function toggle-autocomplete {
    if [ -z "$ZSH_AUTOSUGGEST_HISTORY_IGNORE" ]; then
        export ZSH_AUTOSUGGEST_HISTORY_IGNORE=\*
    else
        unset ZSH_AUTOSUGGEST_HISTORY_IGNORE
    fi
}

function aws_profile () {
    if [ "$1" = "-u" ]; then
        unset AWS_PROFILE
        rm -f "$AWS_PROFILE_FILE"
        return
    fi

    local PROFILES=($(cat "$AWS_CONFIG_FILE" | grep profile | awk '{print substr($2, 1, length($2)-1)}'))
        
    profile=$(printf '%s\n' "${PROFILES[@]}" | fzf --header="Select AWS Profile")
    if [ -n "$profile" ]; then
        export AWS_PROFILE=$profile
        echo "export AWS_PROFILE=$profile" > "$AWS_PROFILE_FILE"
    fi
}

function aws_region() {
    if [ "$1" = "-u" ]; then
        unset AWS_DEFAULT_REGION
        rm -f "$AWS_REGION_FILE"
        return
    fi

    local REGIONS=($(cat "$AWS_CONFIG_FILE" | grep region | awk '{print $3}' | sort | uniq))

    region=$(printf '%s\n' "${REGIONS[@]}" | fzf --header="Select AWS Region")
    if [ -n "$region" ]; then
        export AWS_DEFAULT_REGION=$region
        echo "export AWS_DEFAULT_REGION=$region" >> "$AWS_REGION_FILE"
    fi
}

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
